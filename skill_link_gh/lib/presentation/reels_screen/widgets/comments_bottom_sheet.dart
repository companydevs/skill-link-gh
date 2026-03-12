import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_link_gh/provider/comments_provider.dart';
import 'package:skill_link_gh/domain/models/comment_model.dart';
import 'package:skill_link_gh/widgets/user_avatar_widget.dart';

class CommentsBottomSheet extends ConsumerStatefulWidget {
  final String reelId;
  final String reelAuthor;

  const CommentsBottomSheet({
    super.key,
    required this.reelId,
    required this.reelAuthor,
  });

  @override
  ConsumerState<CommentsBottomSheet> createState() =>
      _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends ConsumerState<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // Debouncing: prevent multiple rapid comment likes
  final Set<String> _likingComments = {};
  DateTime _lastCommentLikeTime = DateTime.now();

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Debounced comment like function to prevent multiple rapid likes
  void _debouncedCommentLike(String commentId, bool isLiked) {
    final now = DateTime.now();

    // Prevent likes within 500ms of each other
    if (now.difference(_lastCommentLikeTime).inMilliseconds < 500) {
      print('⚠️ Comment like debounced - too fast');
      return;
    }

    // Prevent multiple likes on the same comment
    if (_likingComments.contains(commentId)) {
      print('⚠️ Comment like already in progress: $commentId');
      return;
    }

    _lastCommentLikeTime = now;
    _likingComments.add(commentId);

    // Perform the like with cleanup
    Future.microtask(() async {
      try {
        await ref
            .read(commentsNotifierProvider(widget.reelId).notifier)
            .toggleLike(commentId, isLiked);
      } finally {
        _likingComments.remove(commentId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final commentsAsync = ref.watch(commentsNotifierProvider(widget.reelId));
    final currentUser = FirebaseAuth.instance.currentUser;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Comments',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Comments list
          Expanded(
            child: commentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load comments',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref
                            .read(
                              commentsNotifierProvider(widget.reelId).notifier,
                            )
                            .loadComments();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (comments) {
                if (comments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No comments yet',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Be the first to comment!',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return _CommentItem(
                      comment: comment,
                      reelId: widget.reelId,
                      currentUserId: currentUser?.uid,
                      onLike: () {
                        _debouncedCommentLike(comment.id, comment.isLiked);
                      },
                      onDelete: () {
                        ref
                            .read(
                              commentsNotifierProvider(widget.reelId).notifier,
                            )
                            .deleteComment(comment.id, comment.userId);
                      },
                    );
                  },
                );
              },
            ),
          ),

          const Divider(height: 1),

          // Comment input
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 8,
            ),
            child: Row(
              children: [
                // User avatar
                UserAvatarWidget(
                  imageUrl: currentUser?.photoURL,
                  name: currentUser?.displayName ?? 'User',
                  size: 32,
                  semanticLabel: 'Your profile picture',
                ),
                const SizedBox(width: 12),

                // Text field
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceVariant.withOpacity(
                        0.5,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),

                const SizedBox(width: 8),

                // Send button
                IconButton(
                  onPressed: () {
                    final text = _commentController.text.trim();
                    if (text.isNotEmpty) {
                      ref
                          .read(
                            commentsNotifierProvider(widget.reelId).notifier,
                          )
                          .addComment(text);
                      _commentController.clear();
                      _focusNode.unfocus();
                    }
                  },
                  icon: Icon(Icons.send, color: theme.colorScheme.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentItem extends StatelessWidget {
  final Comment comment;
  final String reelId;
  final String? currentUserId;
  final VoidCallback onLike;
  final VoidCallback onDelete;

  const _CommentItem({
    required this.comment,
    required this.reelId,
    required this.currentUserId,
    required this.onLike,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOwnComment = currentUserId == comment.userId;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User avatar
          UserAvatarWidget(
            imageUrl: comment.userAvatar,
            name: comment.userName,
            size: 32,
            semanticLabel: '${comment.userName} profile picture',
          ),

          const SizedBox(width: 12),

          // Comment content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username and time
                Row(
                  children: [
                    Text(
                      comment.userName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(comment.timestamp),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    if (isOwnComment)
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_horiz,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        onSelected: (value) {
                          if (value == 'delete') {
                            _showDeleteDialog(context);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                      ),
                  ],
                ),

                const SizedBox(height: 4),

                // Comment text
                Text(comment.text, style: theme.textTheme.bodyMedium),

                const SizedBox(height: 8),

                // Like button and count
                Row(
                  children: [
                    GestureDetector(
                      onTap: onLike,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            comment.isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 16,
                            color: comment.isLiked
                                ? Colors.red
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          if (comment.likes > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              comment.likes.toString(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
