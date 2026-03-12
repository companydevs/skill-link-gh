import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:skill_link_gh/data/repository/comments_repository.dart';
import 'package:skill_link_gh/domain/models/comment_model.dart';

class CommentsNotifier extends StateNotifier<AsyncValue<List<Comment>>> {
  final CommentsRepository _repository;
  final String reelId;

  // Like debouncing: prevent multiple simultaneous likes
  final Set<String> _likingComments = {};

  CommentsNotifier(this._repository, this.reelId)
    : super(const AsyncValue.loading()) {
    loadComments();
  }

  Future<void> loadComments() async {
    state = const AsyncValue.loading();
    try {
      final comments = await _repository.fetchComments(reelId);
      state = AsyncValue.data(comments);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addComment(String text) async {
    if (text.trim().isEmpty) return;

    try {
      await _repository.addComment(reelId, text.trim());
      // Reload comments to get the new one
      await loadComments();
    } catch (e) {
      print('Failed to add comment: $e');
      // Could show error to user here
    }
  }

  Future<void> toggleLike(String commentId, bool currentIsLiked) async {
    // Prevent multiple simultaneous likes on the same comment
    if (_likingComments.contains(commentId)) {
      print('⚠️ Like already in progress for comment: $commentId');
      return;
    }

    final currentState = state;
    if (!currentState.hasValue) return;

    final comments = currentState.value!;
    final index = comments.indexWhere((c) => c.id == commentId);
    if (index == -1) return;

    // Mark this comment as being liked to prevent race conditions
    _likingComments.add(commentId);

    // Store original state for potential revert
    final originalComments = List<Comment>.from(comments);

    try {
      // Optimistic update
      final updatedComment = comments[index].copyWith(
        isLiked: !currentIsLiked,
        likes: currentIsLiked
            ? comments[index].likes - 1
            : comments[index].likes + 1,
      );

      final updatedComments = List<Comment>.from(comments);
      updatedComments[index] = updatedComment;
      state = AsyncValue.data(updatedComments);

      // Perform the actual like toggle
      await _repository.toggleCommentLike(reelId, commentId, currentIsLiked);
      print('✅ Comment like toggled successfully: $commentId');
    } catch (e) {
      print('❌ Comment like toggle failed for $commentId: $e');

      // Revert on error
      state = AsyncValue.data(originalComments);
    } finally {
      // Always remove from liking set to allow future likes
      _likingComments.remove(commentId);
    }
  }

  Future<void> deleteComment(String commentId, String authorId) async {
    try {
      await _repository.deleteComment(reelId, commentId, authorId);
      // Reload comments to reflect the deletion
      await loadComments();
    } catch (e) {
      print('Failed to delete comment: $e');
    }
  }
}
