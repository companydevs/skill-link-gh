import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:skill_link_gh/data/repository/post_repository.dart';
import 'package:skill_link_gh/domain/models/post_model.dart';

final postRepositoryProvider = Provider((ref) => PostRepository());

final postsNotifierProvider = StateNotifierProvider<PostsNotifier, PostsState>((
  ref,
) {
  final repo = ref.watch(postRepositoryProvider);
  return PostsNotifier(repo);
});

/// State class for posts with loading state
class PostsState {
  final List<PostModel> posts;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  const PostsState({
    this.posts = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });

  PostsState copyWith({
    List<PostModel>? posts,
    bool? isLoading,
    bool? hasMore,
    String? error,
  }) {
    return PostsState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
    );
  }
}

class PostsNotifier extends StateNotifier<PostsState> {
  final PostRepository repository;
  DocumentSnapshot? _lastDoc;

  PostsNotifier(this.repository) : super(const PostsState());

  bool get hasMore => state.hasMore;
  bool get isLoading => state.isLoading;

  bool _likeInProgress = false;

  Future<void> toggleLikeSafe(String postId) async {
    if (_likeInProgress) return; // already processing
    _likeInProgress = true;

    try {
      await toggleLike(postId); // your existing repo call
    } catch (e) {
      log('Toggle like failed: $e');
    } finally {
      _likeInProgress = false;
    }
  }

  /// Load initial posts
  Future<void> loadInitialPosts() async {
    if (state.isLoading) return;

    log('🔄 Loading initial posts...');
    state = state.copyWith(isLoading: true, error: null);

    try {
      final posts = await repository.fetchPosts(limit: 10);
      _lastDoc = posts.isNotEmpty ? null : _lastDoc; // optional pagination

      log('✅ Loaded ${posts.length} posts');
      state = state.copyWith(
        posts: posts,
        isLoading: false,
        hasMore: posts.length >= 10,
      );
    } catch (e) {
      log('❌ Error loading posts: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load more posts for pagination
  Future<void> loadMorePosts() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final posts = await repository.fetchPosts(
        startAfter: _lastDoc,
        limit: 10,
      );

      state = state.copyWith(
        posts: [...state.posts, ...posts],
        isLoading: false,
        hasMore: posts.length >= 10,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Refresh posts
  Future<void> refreshPosts() async {
    _lastDoc = null;
    state = state.copyWith(hasMore: true);
    await loadInitialPosts();
  }

  /// Toggle Like
  Future<void> toggleLike(String postId) async {
    final index = state.posts.indexWhere((post) => post.id == postId);
    if (index == -1) return;

    final post = state.posts[index];
    final wasLiked = post.isLiked;
    final newLikeCount = wasLiked ? post.likes - 1 : post.likes + 1;

    // Update likedBy list
    List<LikedByUser> newLikedBy = List.from(post.likedBy);

    if (wasLiked) {
      // Remove current user from likedBy when unliking
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId != null) {
        newLikedBy.removeWhere((user) => user.userId == currentUserId);
      }

      // If likes become 0, clear the entire list
      if (newLikeCount == 0) {
        newLikedBy = [];
      }
    } else {
      // When liking, add current user to the beginning of likedBy list
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Fetch current user data from Firestore
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();

          if (userDoc.exists) {
            final userData = userDoc.data();
            final userName =
                userData?['name'] ??
                userData?['username'] ??
                userData?['displayName'] ??
                currentUser.displayName ??
                'You';
            final userImage =
                userData?['profileImage'] ??
                userData?['photoUrl'] ??
                currentUser.photoURL ??
                '';

            // Add current user at the beginning
            newLikedBy.insert(
              0,
              LikedByUser(
                userId: currentUser.uid,
                userName: userName,
                userImage: userImage,
              ),
            );

            // Keep only the first 3 users
            if (newLikedBy.length > 3) {
              newLikedBy = newLikedBy.sublist(0, 3);
            }
          }
        } catch (e) {
          log('Error fetching user data: $e');
        }
      }
    }

    // Optimistic update
    final updatedPosts = [
      ...state.posts.sublist(0, index),
      post.copyWith(
        isLiked: !wasLiked,
        likes: newLikeCount,
        likedBy: newLikedBy,
      ),
      ...state.posts.sublist(index + 1),
    ];

    state = state.copyWith(posts: updatedPosts);

    // Perform actual like toggle
    await repository.toggleLike(postId);
  }

  /// Toggle Save
  Future<void> toggleSave(String postId) async {
    final index = state.posts.indexWhere((post) => post.id == postId);
    if (index == -1) return;

    final post = state.posts[index];

    // Optional: If you have repository action for saving
    await repository.toggleSave(postId, post.isSaved);

    final updatedPosts = [
      ...state.posts.sublist(0, index),
      post.copyWith(isSaved: !post.isSaved),
      ...state.posts.sublist(index + 1),
    ];

    state = state.copyWith(posts: updatedPosts);
  }
}
