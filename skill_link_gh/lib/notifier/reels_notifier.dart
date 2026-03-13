// providers/reels_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:skill_link_gh/data/repository/reels_repositoty.dart';
import 'package:skill_link_gh/domain/models/reel_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReelsNotifier extends StateNotifier<AsyncValue<List<Reel>>> {
  final ReelsRepository _repository;

  // Performance optimization: track loading state and pagination
  bool _isLoadingMore = false;
  DocumentSnapshot? _lastDocument;
  bool _hasMoreReels = true;

  // Like debouncing: prevent multiple simultaneous likes
  final Set<String> _likingReels = {};

  // Lightweight chunk size for smooth scrolling
  static const int _chunkSize = 3; // Very small chunks for smooth experience
  static const int _initialLoadSize = 5; // Small initial load

  ReelsNotifier(this._repository) : super(const AsyncValue.data([])) {
    // Start with empty data, load when requested
  }

  Future<void> loadInitialReels() async {
    if (state.isLoading) return; // Prevent multiple simultaneous loads

    state = const AsyncValue.loading();

    // Reset pagination state
    _lastDocument = null;
    _hasMoreReels = true;

    try {
      final reels = await _repository.fetchReels(
        limit: _initialLoadSize,
        useCache: true, // Use cache for better performance
      );

      // Store last document for pagination
      if (reels.isNotEmpty) {
        // We need to get the document snapshot for pagination
        final lastReelId = reels.last.id;
        _lastDocument = await FirebaseFirestore.instance
            .collection('reels')
            .doc(lastReelId)
            .get();
      }

      _hasMoreReels = reels.length == _initialLoadSize;
      state = AsyncValue.data(reels);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> loadMoreReels() async {
    if (_isLoadingMore || !_hasMoreReels || !state.hasValue) {
      return;
    }

    _isLoadingMore = true;

    try {
      final currentReels = state.value!;

      final newReels = await _repository.fetchReels(
        limit: _chunkSize,
        startAfter: _lastDocument,
        useCache: true,
      );

      if (newReels.isNotEmpty) {
        // Update last document for next pagination
        final lastReelId = newReels.last.id;
        _lastDocument = await FirebaseFirestore.instance
            .collection('reels')
            .doc(lastReelId)
            .get();

        // Combine with existing reels
        final allReels = [...currentReels, ...newReels];
        state = AsyncValue.data(allReels);

        // Check if we have more reels to load
        _hasMoreReels = newReels.length == _chunkSize;
      } else {
        _hasMoreReels = false;
      }
    } catch (e) {
      // Don't update state on error, just log it
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> refreshReels() async {
    await loadInitialReels();
  }

  Future<void> toggleLike(String reelId) async {
    // Prevent multiple simultaneous likes on the same reel
    if (_likingReels.contains(reelId)) {
      return;
    }

    final currentState = state;
    if (!currentState.hasValue) return;

    final reels = currentState.value!;
    final index = reels.indexWhere((r) => r.id == reelId);
    if (index == -1) return;

    final currentReel = reels[index];
    final currentIsLiked = currentReel.isLiked;

    // Mark this reel as being liked to prevent race conditions
    _likingReels.add(reelId);

    // INSTANT optimistic update
    final updatedReel = currentReel.copyWith(
      isLiked: !currentIsLiked,
      likes: currentIsLiked ? currentReel.likes - 1 : currentReel.likes + 1,
    );

    final updatedReels = List<Reel>.from(reels);
    updatedReels[index] = updatedReel;
    state = AsyncValue.data(updatedReels);

    // Perform the actual like toggle in background (fire-and-forget)
    _repository
        .toggleLike(reelId, currentIsLiked)
        .then((_) {
          _likingReels.remove(reelId);
        })
        .catchError((e) {
          // Revert on error
          state = AsyncValue.data(reels);
          _likingReels.remove(reelId);
        });
  }

  // Add new reel locally after successful upload
  Future<void> addNewReelLocally(Reel newReel) async {
    final currentReels = state.value ?? [];
    state = AsyncValue.data([newReel, ...currentReels]);
  }

  // Getters for UI state
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreReels => _hasMoreReels;
  int get currentReelsCount => state.value?.length ?? 0;
}
