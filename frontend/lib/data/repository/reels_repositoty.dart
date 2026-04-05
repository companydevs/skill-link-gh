// data/repositories/reels_repository.dart
import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:skill_link_gh/domain/models/reel_model.dart';
import 'package:skill_link_gh/services/backend_api_service.dart';
import 'package:video_compress/video_compress.dart';
import 'package:flutter/foundation.dart';

class ReelsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final BackendApiService _backend = BackendApiService();

  // Cache for reels data to improve performance
  static final Map<String, Reel> _reelsCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  // Lightweight chunk size for better performance
  static const int _defaultChunkSize =
      5; // Reduced from 10 for better performance
  static const int _maxCachedReels = 50; // Limit cache size

  /// Clear expired cache entries to prevent memory bloat
  void _cleanCache() {
    final now = DateTime.now();
    final expiredKeys = _cacheTimestamps.entries
        .where((entry) => now.difference(entry.value) > _cacheExpiry)
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      _reelsCache.remove(key);
      _cacheTimestamps.remove(key);
    }

    // Limit cache size
    if (_reelsCache.length > _maxCachedReels) {
      final sortedEntries = _cacheTimestamps.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));

      final toRemove = sortedEntries.take(_reelsCache.length - _maxCachedReels);
      for (final entry in toRemove) {
        _reelsCache.remove(entry.key);
        _cacheTimestamps.remove(entry.key);
      }
    }
  }

  /// Get cached reel if available and not expired
  Reel? _getCachedReel(String reelId) {
    final timestamp = _cacheTimestamps[reelId];
    if (timestamp != null &&
        DateTime.now().difference(timestamp) < _cacheExpiry) {
      return _reelsCache[reelId];
    }
    return null;
  }

  /// Cache a reel with timestamp
  void _cacheReel(Reel reel) {
    _reelsCache[reel.id] = reel;
    _cacheTimestamps[reel.id] = DateTime.now();
  }

  /// Validate video URL and check if it's accessible
  Future<bool> validateVideoUrl(String url) async {
    try {
      if (url.isEmpty) return false;

      final uri = Uri.parse(url);
      if (!uri.hasScheme || (!uri.isScheme('http') && !uri.isScheme('https'))) {
        return false;
      }

      // For Firebase Storage URLs, check if they contain required parameters
      if (url.contains('firebasestorage.googleapis.com')) {
        return url.contains('alt=media') && url.contains('token=');
      }

      return true;
    } catch (e) {
      print('❌ URL validation error: $e');
      return false;
    }
  }

  Future<List<Reel>> fetchReels({
    int limit = _defaultChunkSize,
    DocumentSnapshot? startAfter,
    bool useCache = true,
    double? lat,
    double? lng,
    double? radiusKm,
    String? lastContentId,
  }) async {
    // ── Try backend recommendation engine ──────────────────────────────────
    try {
      final backendReels = await _backend.getRecommendedReels(
        lat: lat,
        lng: lng,
        radiusKm: radiusKm,
        lastContentId: lastContentId,
        pageSize: limit,
      );

      if (backendReels.isNotEmpty) {
        log(
          '✅ ReelsRepository: using backend recommendations (${backendReels.length} reels)',
        );
        return _mapBackendReels(backendReels);
      }
    } catch (e) {
      log(
        '⚠️ ReelsRepository: backend unavailable, falling back to Firestore: $e',
      );
    }

    // ── Firestore fallback ─────────────────────────────────────────────────
    log('🔄 ReelsRepository: fetching from Firestore');
    return _fetchReelsFromFirestore(
      limit: limit,
      startAfter: startAfter,
      useCache: useCache,
    );
  }

  /// Maps backend JSON to Reel list.
  List<Reel> _mapBackendReels(List<Map<String, dynamic>> raw) {
    return raw
        .map((data) {
          return Reel(
            id: data['firestoreId'] as String? ?? '',
            videoUrl: data['videoUrl'] as String? ?? '',
            artisanName: data['artisanName'] as String? ?? 'Unknown',
            artisanAvatar: data['artisanAvatar'] as String? ?? '',
            artisanCategory: data['artisanCategory'] as String? ?? '',
            artisanSemanticLabel: '',
            description: data['description'] as String? ?? '',
            likes: data['likes'] as int? ?? 0,
            comments: data['comments'] as int? ?? 0,
            shares: data['shares'] as int? ?? 0,
            isLiked: false, // like state loaded separately by notifier
            timestamp: data['createdAt'] != null
                ? DateTime.tryParse(data['createdAt'].toString()) ??
                      DateTime.now()
                : DateTime.now(),
          );
        })
        .where((r) => r.videoUrl.isNotEmpty)
        .toList();
  }

  Future<List<Reel>> _fetchReelsFromFirestore({
    int limit = _defaultChunkSize,
    DocumentSnapshot? startAfter,
    bool useCache = true,
  }) async {
    try {
      // Clean expired cache entries
      if (useCache) {
        _cleanCache();
      }

      print("🔍 Fetching $limit reels from Firestore...");

      Query query = _firestore
          .collection('reels')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      print("📊 Found ${snapshot.docs.length} reels in Firestore");

      final currentUserId = _auth.currentUser?.uid;
      print("👤 Current user ID: $currentUserId");

      final reels = <Reel>[];
      final futures = <Future<void>>[];

      // Process reels in parallel for better performance
      for (var doc in snapshot.docs) {
        futures.add(_processReelDocument(doc, currentUserId, reels, useCache));
      }

      // Wait for all processing to complete
      await Future.wait(futures);

      print("🎉 Successfully processed ${reels.length} reels");
      return reels;
    } catch (e) {
      print('❌ Error fetching reels: $e');
      rethrow;
    }
  }

  /// Process a single reel document (extracted for parallel processing)
  Future<void> _processReelDocument(
    QueryDocumentSnapshot doc,
    String? currentUserId,
    List<Reel> reels,
    bool useCache,
  ) async {
    try {
      // Check cache first
      if (useCache) {
        final cachedReel = _getCachedReel(doc.id);
        if (cachedReel != null) {
          reels.add(cachedReel);
          print("💾 Using cached reel: ${doc.id}");
          return;
        }
      }

      final data = doc.data() as Map<String, dynamic>;
      print("🎬 Processing reel: ${doc.id}");

      // Validate video URL before processing
      final videoUrl = data['videoUrl'] ?? '';
      if (videoUrl.isEmpty || !(await validateVideoUrl(videoUrl))) {
        print('⚠️ Skipping reel ${doc.id}: invalid or empty video URL');
        return;
      }

      // Check if current user has liked this reel (async operation)
      bool isLiked = false;
      if (currentUserId != null) {
        try {
          final likeDoc = await doc.reference
              .collection('likes')
              .doc(currentUserId)
              .get();
          isLiked = likeDoc.exists;
        } catch (e) {
          print('⚠️ Error checking like status for ${doc.id}: $e');
          // Continue without like status rather than failing
        }
      }

      print(
        "✅ Adding reel ${doc.id} with URL: ${videoUrl.substring(0, 50)}...",
      );

      final reel = Reel(
        id: doc.id,
        videoUrl: videoUrl,
        artisanName: data['artisanName'] ?? 'Unknown Artisan',
        artisanAvatar: data['artisanAvatar'] ?? '',
        artisanCategory: data['artisanCategory'] ?? 'General',
        artisanSemanticLabel: data['artisanSemanticLabel'] ?? '',
        description: data['description'] ?? 'Check out this amazing work!',
        likes: (data['likes'] ?? 0) as int,
        comments: (data['comments'] ?? 0) as int,
        shares: (data['shares'] ?? 0) as int,
        isLiked: isLiked,
        timestamp:
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

      // Cache the reel for future use
      if (useCache) {
        _cacheReel(reel);
      }

      reels.add(reel);
    } catch (e) {
      print('⚠️ Error processing reel ${doc.id}: $e');
      // Continue processing other reels instead of failing completely
    }
  }

  /// Toggle like on a reel (optimistic + Firestore transaction)
  Future<void> toggleLike(String reelId, bool currentIsLiked) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final reelRef = _firestore.collection('reels').doc(reelId);
    final likeRef = reelRef.collection('likes').doc(uid);

    await _firestore.runTransaction((transaction) async {
      final likeSnap = await transaction.get(likeRef);

      if (likeSnap.exists) {
        // Unlike
        transaction.delete(likeRef);
        transaction.update(reelRef, {'likes': FieldValue.increment(-1)});
      } else {
        // Like
        transaction.set(likeRef, {'likedAt': FieldValue.serverTimestamp()});
        transaction.update(reelRef, {'likes': FieldValue.increment(1)});
      }
    });
  }

  /// Upload video to Firebase Storage with progress callback and compression
  Future<String> uploadVideo(File file, Function(double) onProgress) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("User not authenticated");

    // Validate file
    if (!file.existsSync()) {
      throw Exception("Video file does not exist");
    }

    File videoToUpload = file;
    MediaInfo? compressedInfo;

    try {
      // Compress video to reduce size and resolution
      debugPrint('🎬 Starting video compression...');

      final info = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.MediumQuality, // Good balance
        deleteOrigin: false, // Keep original
        includeAudio: true,
      );

      if (info != null && info.file != null) {
        compressedInfo = info;
        videoToUpload = info.file!;
        debugPrint('✅ Compression complete: ${info.filesize} bytes');
        debugPrint(
          '📊 Original: ${file.lengthSync()} → Compressed: ${info.filesize}',
        );

        // Update progress for compression complete
        onProgress(0.3); // 30% for compression
      }
    } catch (e) {
      debugPrint('⚠️ Compression failed, uploading original: $e');
      // Continue with original file if compression fails
    }

    // Check file size after compression
    final fileSize = videoToUpload.lengthSync();
    if (fileSize > 100 * 1024 * 1024) {
      throw Exception(
        "Video file too large even after compression (max 100MB)",
      );
    }

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';
    final ref = _storage.ref().child('reels/$uid/$fileName');

    // Set metadata for better streaming
    final metadata = SettableMetadata(
      contentType: 'video/mp4',
      cacheControl: 'max-age=3600',
      customMetadata: {
        'uploadedBy': uid,
        'uploadedAt': DateTime.now().toIso8601String(),
        'compressed': compressedInfo != null ? 'true' : 'false',
      },
    );

    final uploadTask = ref.putFile(videoToUpload, metadata);

    uploadTask.snapshotEvents.listen((taskSnapshot) {
      // Map upload progress from 30% to 100%
      final uploadProgress =
          taskSnapshot.bytesTransferred / taskSnapshot.totalBytes;
      final totalProgress =
          0.3 + (uploadProgress * 0.7); // 30% compression + 70% upload
      onProgress(totalProgress.clamp(0.0, 1.0));
    });

    final taskSnapshot = await uploadTask;
    final downloadUrl = await taskSnapshot.ref.getDownloadURL();

    // Clean up compressed file if it was created
    if (compressedInfo != null && videoToUpload.path != file.path) {
      try {
        await videoToUpload.delete();
      } catch (e) {
        debugPrint('⚠️ Failed to delete compressed temp file: $e');
      }
    }

    // Validate the download URL
    if (downloadUrl.isEmpty) {
      throw Exception("Failed to get video download URL");
    }

    return downloadUrl;
  }

  /// Create reel using secure Cloud Function
  Future<void> createReel({
    required String videoUrl,
    required String description,
    String? artisanName,
    String? artisanAvatar,
    String? artisanCategory,
    String? artisanSemanticLabel,
  }) async {
    try {
      final callable = _functions.httpsCallable('createReel');

      await callable.call({
        'videoUrl': videoUrl,
        'description': description,
        if (artisanName != null) 'artisanName': artisanName,
        if (artisanAvatar != null) 'artisanAvatar': artisanAvatar,
        if (artisanCategory != null) 'artisanCategory': artisanCategory,
        if (artisanSemanticLabel != null)
          'artisanSemanticLabel': artisanSemanticLabel,
      });
    } on FirebaseFunctionsException catch (e) {
      print('Cloud Function error: ${e.code} - ${e.message}');
      throw Exception(e.message ?? 'Failed to create reel');
    } catch (e) {
      print('Error calling createReel: $e');
      rethrow;
    }
  }
}
