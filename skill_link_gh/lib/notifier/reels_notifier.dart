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

    print("🚀 Loading initial $_initialLoadSize reels...");
    state = const AsyncValue.loading();

    // Reset pagination state
    _lastDocument = null;
    _hasMoreReels = true;

    try {
      final reels = await _repository.fetchReels(
        limit: _initialLoadSize,
        useCache: true, // Use cache for better performance
      );

      print("📱 Loaded ${reels.length} initial reels successfully");

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
      print("✅ Initial reels state updated successfully");
    } catch (e, stackTrace) {
      print("❌ Error loading initial reels: $e");
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> loadMoreReels() async {
    if (_isLoadingMore || !_hasMoreReels || !state.hasValue) {
      print(
        "📄 Load more skipped: loading=$_isLoadingMore, hasMore=$_hasMoreReels",
      );
      return;
    }

    _isLoadingMore = true;
    print("📄 Loading $_chunkSize more reels...");

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

        print(
          "📄 Loaded ${newReels.length} more reels. Total: ${allReels.length}",
        );

        // Check if we have more reels to load
        _hasMoreReels = newReels.length == _chunkSize;
      } else {
        _hasMoreReels = false;
        print("📄 No more reels to load");
      }
    } catch (e) {
      print("❌ Error loading more reels: $e");
      // Don't update state on error, just log it
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> refreshReels() async {
    print("🔄 Refreshing reels...");
    await loadInitialReels();
  }

  Future<void> toggleLike(String reelId) async {
    // Prevent multiple simultaneous likes on the same reel
    if (_likingReels.contains(reelId)) {
      print('⚠️ Like already in progress for reel: $reelId');
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

    try {
      // Optimistic update - instant UI response
      final updatedReel = currentReel.copyWith(
        isLiked: !currentIsLiked,
        likes: currentIsLiked ? currentReel.likes - 1 : currentReel.likes + 1,
      );

      final updatedReels = List<Reel>.from(reels);
      updatedReels[index] = updatedReel;
      state = AsyncValue.data(updatedReels);

      // Perform the actual like toggle in background
      await _repository.toggleLike(reelId, currentIsLiked);
      print('✅ Like toggled successfully for reel: $reelId');
    } catch (e) {
      print('❌ Like toggle failed for reel $reelId: $e');

      // Revert on error
      state = AsyncValue.data(reels);
    } finally {
      // Always remove from liking set to allow future likes
      _likingReels.remove(reelId);
    }
  }

  // Add new reel locally after successful upload
  Future<void> addNewReelLocally(Reel newReel) async {
    final currentReels = state.value ?? [];
    state = AsyncValue.data([newReel, ...currentReels]);
    print("✅ Added new reel locally: ${newReel.id}");
  }

  // Getters for UI state
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreReels => _hasMoreReels;
  int get currentReelsCount => state.value?.length ?? 0;
}
