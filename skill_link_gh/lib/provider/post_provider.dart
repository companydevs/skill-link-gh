import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:skill_link_gh/data/repository/post_repository.dart';
import 'package:skill_link_gh/domain/models/post_model.dart';

final postRepositoryProvider = Provider((ref) => PostRepository());

final postsNotifierProvider =
    StateNotifierProvider<PostsNotifier, List<PostModel>>((ref) {
  final repo = ref.watch(postRepositoryProvider);
  return PostsNotifier(repo);
});

class PostsNotifier extends StateNotifier<List<PostModel>> {
  final PostRepository repository;
  bool _hasMore = true;
  bool _isLoading = false;
  DocumentSnapshot? _lastDoc;

  PostsNotifier(this.repository) : super([]);

  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;

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
    if (_isLoading) return;
    _isLoading = true;

    final posts = await repository.fetchPosts(limit: 10);
    if (posts.length < 10) _hasMore = false;
    _lastDoc = posts.isNotEmpty ? null : _lastDoc; // optional pagination
    state = posts;
    _isLoading = false;
  }

  /// Load more posts for pagination
  Future<void> loadMorePosts() async {
    if (_isLoading || !_hasMore) return;
    _isLoading = true;

    final posts = await repository.fetchPosts(startAfter: _lastDoc, limit: 10);
    if (posts.length < 10) _hasMore = false;
    state = [...state, ...posts];
    _isLoading = false;
  }

  /// Refresh posts
  Future<void> refreshPosts() async {
    _hasMore = true;
    await loadInitialPosts();
  }

  /// Toggle Like
  Future<void> toggleLike(String postId) async {
    final index = state.indexWhere((post) => post.id == postId);
    if (index == -1) return;

    final post = state[index];
    await repository.toggleLike(postId);

    state = [
      ...state.sublist(0, index),
      post.copyWith(
        isLiked: !post.isLiked,
        likes: post.isLiked ? post.likes - 1 : post.likes + 1,
      ),
      ...state.sublist(index + 1),
    ];
  }

  /// Toggle Save
  Future<void> toggleSave(String postId) async {
    final index = state.indexWhere((post) => post.id == postId);
    if (index == -1) return;

    final post = state[index];

    // Optional: If you have repository action for saving
    await repository.toggleSave(postId, post.isSaved);

    state = [
      ...state.sublist(0, index),
      post.copyWith(isSaved: !post.isSaved),
      ...state.sublist(index + 1),
    ];
  }
}
