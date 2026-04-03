import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:skill_link_gh/data/repository/reels_repositoty.dart';
import 'package:skill_link_gh/domain/models/reel_model.dart';

class ReelsNotifier extends StateNotifier<AsyncValue<List<Reel>>> {
  final ReelsRepository _repository;

  StreamSubscription<QuerySnapshot>? _reelsSubscription;
  final Set<String> _likingReels = {};
  bool _isLoadingMore = false;
  bool _hasMoreReels = true;

  static const int _initialLoadSize = 10;

  ReelsNotifier(this._repository) : super(const AsyncValue.data([]));

  Future<void> loadInitialReels() async {
    if (state.isLoading) return;
    state = const AsyncValue.loading();
    _reelsSubscription?.cancel();

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      // Real-time stream — handles deletions, count updates, new reels
      _reelsSubscription = FirebaseFirestore.instance
          .collection('reels')
          .orderBy('createdAt', descending: true)
          .limit(_initialLoadSize)
          .snapshots()
          .listen(
            (snapshot) async {
              try {
                final reels = <Reel>[];
                for (final doc in snapshot.docs) {
                  final data = doc.data();
                  final videoUrl = data['videoUrl'] as String? ?? '';
                  // Skip docs with no valid video URL (deleted/broken)
                  if (videoUrl.isEmpty) continue;

                  bool isLiked = false;
                  if (uid != null) {
                    try {
                      final likeDoc = await doc.reference
                          .collection('likes')
                          .doc(uid)
                          .get();
                      isLiked = likeDoc.exists;
                    } catch (_) {}
                  }

                  reels.add(
                    Reel(
                      id: doc.id,
                      videoUrl: videoUrl,
                      artisanName: data['artisanName'] ?? 'Unknown',
                      artisanAvatar: data['artisanAvatar'] ?? '',
                      artisanCategory: data['artisanCategory'] ?? '',
                      artisanSemanticLabel: data['artisanSemanticLabel'] ?? '',
                      description: data['description'] ?? '',
                      likes: (data['likes'] ?? 0) as int,
                      comments: (data['comments'] ?? 0) as int,
                      shares: (data['shares'] ?? 0) as int,
                      isLiked: isLiked,
                      timestamp:
                          (data['createdAt'] as Timestamp?)?.toDate() ??
                          DateTime.now(),
                    ),
                  );
                }
                if (mounted) state = AsyncValue.data(reels);
              } catch (e, st) {
                log('ReelsNotifier stream error: $e');
                if (mounted) state = AsyncValue.error(e, st);
              }
            },
            onError: (e, st) {
              log('ReelsNotifier stream error: $e');
              if (mounted) state = AsyncValue.error(e, st);
            },
          );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMoreReels() async {
    if (_isLoadingMore || !_hasMoreReels || !state.hasValue) return;
    _isLoadingMore = true;
    try {
      final current = state.value!;
      if (current.isEmpty) {
        _isLoadingMore = false;
        return;
      }

      final lastId = current.last.id;
      final lastDoc = await FirebaseFirestore.instance
          .collection('reels')
          .doc(lastId)
          .get();

      final snap = await FirebaseFirestore.instance
          .collection('reels')
          .orderBy('createdAt', descending: true)
          .startAfterDocument(lastDoc)
          .limit(5)
          .get();

      if (snap.docs.isEmpty) {
        _hasMoreReels = false;
        _isLoadingMore = false;
        return;
      }

      final uid = FirebaseAuth.instance.currentUser?.uid;
      final more = <Reel>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        final videoUrl = data['videoUrl'] as String? ?? '';
        if (videoUrl.isEmpty) continue;
        bool isLiked = false;
        if (uid != null) {
          try {
            final likeDoc = await doc.reference
                .collection('likes')
                .doc(uid)
                .get();
            isLiked = likeDoc.exists;
          } catch (_) {}
        }
        more.add(
          Reel(
            id: doc.id,
            videoUrl: videoUrl,
            artisanName: data['artisanName'] ?? 'Unknown',
            artisanAvatar: data['artisanAvatar'] ?? '',
            artisanCategory: data['artisanCategory'] ?? '',
            artisanSemanticLabel: data['artisanSemanticLabel'] ?? '',
            description: data['description'] ?? '',
            likes: (data['likes'] ?? 0) as int,
            comments: (data['comments'] ?? 0) as int,
            shares: (data['shares'] ?? 0) as int,
            isLiked: isLiked,
            timestamp:
                (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          ),
        );
      }

      _hasMoreReels = snap.docs.length == 5;
      if (mounted) state = AsyncValue.data([...current, ...more]);
    } catch (e) {
      log('loadMoreReels error: $e');
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> refreshReels() async {
    await loadInitialReels();
  }

  void toggleLike(String reelId) {
    if (_likingReels.contains(reelId)) return;
    final current = state.value;
    if (current == null) return;
    final index = current.indexWhere((r) => r.id == reelId);
    if (index == -1) return;

    final reel = current[index];
    _likingReels.add(reelId);

    // Optimistic update
    final updated = List<Reel>.from(current);
    updated[index] = reel.copyWith(
      isLiked: !reel.isLiked,
      likes: reel.isLiked ? reel.likes - 1 : reel.likes + 1,
    );
    state = AsyncValue.data(updated);

    Future.microtask(() {
      _repository
          .toggleLike(reelId, reel.isLiked)
          .then((_) {
            _likingReels.remove(reelId);
          })
          .catchError((e) {
            // Revert
            final cur = state.value;
            if (cur != null) {
              final idx = cur.indexWhere((r) => r.id == reelId);
              if (idx != -1) {
                final rev = List<Reel>.from(cur);
                rev[idx] = reel;
                if (mounted) state = AsyncValue.data(rev);
              }
            }
            _likingReels.remove(reelId);
          });
    });
  }

  @override
  void dispose() {
    _reelsSubscription?.cancel();
    super.dispose();
  }

  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreReels => _hasMoreReels;
  int get currentReelsCount => state.value?.length ?? 0;
}
