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

  // Like state: reelId -> isLiked (source of truth for UI, never overwritten by stream)
  final Map<String, bool> _likedState = {};

  // Debounce: reelId -> pending timer
  final Map<String, Timer> _likeDebounce = {};

  // Track the "intended" like state after all pending taps
  final Map<String, bool> _pendingLikeState = {};

  // Original like state before debounce started (for revert on error)
  final Map<String, bool> _originalLikeState = {};

  bool _isLoadingMore = false;
  bool _hasMoreReels = true;

  static const int _initialLoadSize = 10;

  ReelsNotifier(this._repository) : super(const AsyncValue.data([]));

  Future<void> loadInitialReels() async {
    if (state.isLoading) return;
    state = const AsyncValue.loading();
    _reelsSubscription?.cancel();

    final uid = FirebaseAuth.instance.currentUser?.uid;

    try {
      // Load like status once upfront — not on every stream event
      if (uid != null) {
        final snap = await FirebaseFirestore.instance
            .collection('reels')
            .orderBy('createdAt', descending: true)
            .limit(_initialLoadSize)
            .get();

        for (final doc in snap.docs) {
          try {
            final likeDoc = await doc.reference
                .collection('likes')
                .doc(uid)
                .get();
            _likedState[doc.id] = likeDoc.exists;
          } catch (_) {
            _likedState[doc.id] = false;
          }
        }
      }

      // Now subscribe to real-time updates — counts only, never overwrite like state
      _reelsSubscription = FirebaseFirestore.instance
          .collection('reels')
          .orderBy('createdAt', descending: true)
          .limit(_initialLoadSize)
          .snapshots()
          .listen(
            (snapshot) {
              try {
                final reels = <Reel>[];
                for (final doc in snapshot.docs) {
                  final data = doc.data();
                  final videoUrl = data['videoUrl'] as String? ?? '';
                  if (videoUrl.isEmpty) continue;

                  // Use cached like state — never re-fetch from Firestore on stream events
                  final isLiked = _likedState[doc.id] ?? false;

                  // Comment count = top-level comments field on reel doc
                  // (replies are tracked separately per comment)
                  final commentCount = (data['comments'] ?? 0) as int;

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
                      comments: commentCount,
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

        // Load like status for new reels
        if (uid != null && !_likedState.containsKey(doc.id)) {
          try {
            final likeDoc = await doc.reference
                .collection('likes')
                .doc(uid)
                .get();
            _likedState[doc.id] = likeDoc.exists;
          } catch (_) {
            _likedState[doc.id] = false;
          }
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
            isLiked: _likedState[doc.id] ?? false,
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
    _likedState.clear();
    _likeDebounce.forEach((_, t) => t.cancel());
    _likeDebounce.clear();
    _pendingLikeState.clear();
    _originalLikeState.clear();
    await loadInitialReels();
  }

  /// Instant UI toggle + debounced Firestore write.
  /// Rapid taps flip the UI immediately every time.
  /// Firestore write fires 400ms after the last tap.
  void toggleLike(String reelId) {
    final current = state.value;
    if (current == null) return;
    final index = current.indexWhere((r) => r.id == reelId);
    if (index == -1) return;

    final reel = current[index];
    final currentIsLiked = _likedState[reelId] ?? reel.isLiked;
    final newIsLiked = !currentIsLiked;

    // Store original state before any debounce started
    _originalLikeState.putIfAbsent(reelId, () => currentIsLiked);

    // Update cached like state immediately
    _likedState[reelId] = newIsLiked;
    _pendingLikeState[reelId] = newIsLiked;

    // Instant UI update
    final updated = List<Reel>.from(current);
    updated[index] = reel.copyWith(
      isLiked: newIsLiked,
      likes: newIsLiked ? reel.likes + 1 : reel.likes - 1,
    );
    state = AsyncValue.data(updated);

    // Cancel previous debounce timer
    _likeDebounce[reelId]?.cancel();

    // Debounce: write to Firestore 400ms after last tap
    _likeDebounce[reelId] = Timer(const Duration(milliseconds: 400), () async {
      final finalState = _pendingLikeState[reelId];
      final originalState = _originalLikeState[reelId];
      _likeDebounce.remove(reelId);
      _pendingLikeState.remove(reelId);
      _originalLikeState.remove(reelId);

      if (finalState == null || originalState == null) return;
      // If final state == original, net effect is zero — skip write
      if (finalState == originalState) return;

      try {
        // Write the final state: if finalState is liked, we need to like;
        // pass originalState so repository knows what to toggle from
        await _repository.toggleLike(reelId, originalState);
      } catch (e) {
        log('toggleLike Firestore error: $e');
        // Revert UI to original state on error
        _likedState[reelId] = originalState;
        final cur = state.value;
        if (cur != null && mounted) {
          final idx = cur.indexWhere((r) => r.id == reelId);
          if (idx != -1) {
            final rev = List<Reel>.from(cur);
            rev[idx] = cur[idx].copyWith(
              isLiked: originalState,
              likes: originalState ? cur[idx].likes + 1 : cur[idx].likes - 1,
            );
            state = AsyncValue.data(rev);
          }
        }
      }
    });
  }

  /// Called by the comments bottom sheet after posting a comment
  /// so the count updates instantly without waiting for the stream
  void incrementCommentCount(String reelId) {
    final current = state.value;
    if (current == null) return;
    final index = current.indexWhere((r) => r.id == reelId);
    if (index == -1) return;
    final updated = List<Reel>.from(current);
    updated[index] = current[index].copyWith(
      comments: current[index].comments + 1,
    );
    if (mounted) state = AsyncValue.data(updated);
  }

  @override
  void dispose() {
    _reelsSubscription?.cancel();
    _likeDebounce.forEach((_, t) => t.cancel());
    super.dispose();
  }

  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreReels => _hasMoreReels;
  int get currentReelsCount => state.value?.length ?? 0;
}
