import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_link_gh/domain/models/post_model.dart';
import 'package:skill_link_gh/services/backend_api_service.dart';

class PostRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final BackendApiService _backend = BackendApiService();

  /// Fetch posts — tries the recommendation backend first, falls back to Firestore.
  /// [lat]/[lng] are the user's current coordinates for location-aware ranking.
  Future<List<PostModel>> fetchPosts({
    DocumentSnapshot? startAfter,
    int limit = 10,
    double? lat,
    double? lng,
    double? radiusKm,
    String? lastContentId,
  }) async {
    final uid = _auth.currentUser?.uid;

    // ── Try backend recommendation engine ──────────────────────────────────
    try {
      final backendPosts = await _backend.getRecommendedPosts(
        lat: lat,
        lng: lng,
        radiusKm: radiusKm,
        lastContentId: lastContentId,
        pageSize: limit,
      );

      if (backendPosts.isNotEmpty) {
        log(
          '✅ PostRepository: using backend recommendations (${backendPosts.length} posts)',
        );
        return _mapBackendPosts(backendPosts, uid);
      }
    } catch (e) {
      log(
        '⚠️ PostRepository: backend unavailable, falling back to Firestore: $e',
      );
    }

    // ── Firestore fallback ─────────────────────────────────────────────────
    log('🔄 PostRepository: fetching from Firestore');
    Query query = _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) query = query.startAfterDocument(startAfter);

    final snapshot = await query.get();

    return Future.wait(
      snapshot.docs.map((doc) async {
        bool isLiked = false;
        if (uid != null) {
          final likeDoc = await doc.reference
              .collection('likes')
              .doc(uid)
              .get();
          isLiked = likeDoc.exists;
        }
        return PostModel.fromFirestore(
          doc,
        ).copyWith(isLiked: isLiked, likedBy: const []);
      }),
    );
  }

  /// Maps backend JSON response to PostModel list, enriching with like status from Firestore.
  Future<List<PostModel>> _mapBackendPosts(
    List<Map<String, dynamic>> raw,
    String? uid,
  ) async {
    return Future.wait(
      raw.map((data) async {
        final firestoreId = data['firestoreId'] as String? ?? '';
        bool isLiked = false;
        if (uid != null && firestoreId.isNotEmpty) {
          try {
            final likeDoc = await _firestore
                .collection('posts')
                .doc(firestoreId)
                .collection('likes')
                .doc(uid)
                .get();
            isLiked = likeDoc.exists;
          } catch (_) {}
        }
        return PostModel(
          id: firestoreId,
          artisanId: data['artisanId'] ?? '',
          artisanName: data['artisanName'] ?? '',
          artisanImage: data['artisanImage'] ?? '',
          serviceCategory: data['serviceCategory'] ?? '',
          description: data['description'] ?? '',
          pricing: data['pricing'] ?? '',
          postImages: const [],
          likes: data['likes'] ?? 0,
          comments: data['comments'] ?? 0,
          isLiked: isLiked,
          createdAt: data['createdAt'] != null
              ? DateTime.tryParse(data['createdAt'].toString()) ??
                    DateTime.now()
              : DateTime.now(),
        );
      }),
    );
  }

  Future<void> toggleLike(String postId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final postRef = _firestore.collection('posts').doc(postId);
    final likeRef = postRef.collection('likes').doc(user.uid);

    // Fetch current user data
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();

    // Get user name from various possible fields
    final userName =
        userData?['name'] ??
        userData?['username'] ??
        userData?['displayName'] ??
        user.displayName ??
        '';

    final userImage =
        userData?['profileImage'] ??
        userData?['photoUrl'] ??
        user.photoURL ??
        '';

    await _firestore.runTransaction((tx) async {
      final likeSnap = await tx.get(likeRef);

      if (likeSnap.exists) {
        tx.delete(likeRef);
        tx.update(postRef, {'likes': FieldValue.increment(-1)});
      } else {
        tx.set(likeRef, {
          'likedAt': FieldValue.serverTimestamp(),
          'userName': userName,
          'userImage': userImage,
        }, SetOptions(merge: true));
        tx.update(postRef, {'likes': FieldValue.increment(1)});
      }
    });
  }

  /// Toggle save/unsave for the current user
  Future<void> toggleSave(String postId, bool isSaved) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final saveRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('savedPosts')
        .doc(postId);

    if (isSaved) {
      // If currently saved, remove
      await saveRef.delete();
    } else {
      // Otherwise, add with timestamp
      await saveRef.set({
        'postId': postId,
        'savedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Optional: Fetch saved posts for current user
  Future<List<String>> fetchSavedPostIds() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('savedPosts')
        .get();

    return snapshot.docs.map((doc) => doc.id).toList();
  }

  /// Report a post
  Future<void> reportPost(String postId, String reason) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('reports').add({
      'postId': postId,
      'reportedBy': user.uid,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
