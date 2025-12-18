import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sizer/sizer.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Comment Item Widget
/// Displays individual comment with user info, text, and interaction buttons
class CommentItemWidget extends StatelessWidget {
  final String commentId;
  final String commentOwnerId; // ✅ UID of the user who posted
  final String userName;
  final String userAvatar;
  final bool isVerified;
  final String timestamp;
  final String commentText;
  final int likes;
  final int replies;
  final bool isLiked;
  final int level;
  final VoidCallback onLike;
  final VoidCallback onReply;
  final VoidCallback onReport;
  final VoidCallback? onToggleReplies;
  final VoidCallback? onDelete;

  const CommentItemWidget({
    super.key,
    required this.commentId,
    required this.commentOwnerId, // ✅ added
    required this.userName,
    required this.userAvatar,
    required this.isVerified,
    required this.timestamp,
    required this.commentText,
    required this.likes,
    required this.replies,
    required this.isLiked,
    required this.level,
    required this.onLike,
    required this.onReply,
    required this.onReport,
    this.onToggleReplies,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        left: (level * 8.w) + 3.w,
        right: 3.w,
        bottom: 1.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                backgroundImage: CachedNetworkImageProvider(userAvatar),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  userName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isVerified) ...[
                                SizedBox(width: 1.w),
                                Icon(
                                  Icons.verified,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          timestamp,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color:
                                    Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            Icons.more_vert,
                            size: 20,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _showOptionsMenu(context),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    _buildFormattedText(context, commentText),
                    SizedBox(height: 1.h),
                    Row(
                      children: [
                        InkWell(
                          onTap: onLike,
                          child: Row(
                            children: [
                              Icon(
                                isLiked ? Icons.favorite : Icons.favorite_border,
                                size: 18,
                                color: isLiked
                                    ? Colors.red
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                              ),
                              SizedBox(width: 1.w),
                              Text(
                                likes.toString(),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: isLiked
                                          ? Colors.red
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 4.w),
                        InkWell(
                          onTap: onReply,
                          child: Row(
                            children: [
                              Icon(
                                Icons.reply,
                                size: 18,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              SizedBox(width: 1.w),
                              Text(
                                'Reply',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        if (replies > 0 && onToggleReplies != null) ...[
                          SizedBox(width: 4.w),
                          InkWell(
                            onTap: onToggleReplies,
                            child: Text(
                              '$replies ${replies == 1 ? 'reply' : 'replies'}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedText(BuildContext context, String text) {
    final List<TextSpan> spans = [];
    final words = text.split(' ');

    for (int i = 0; i < words.length; i++) {
      final word = words[i];

      if (word.startsWith('@')) {
        spans.add(
          TextSpan(
            text: word,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        );
      } else if (word.startsWith('#')) {
        spans.add(
          TextSpan(
            text: word,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: word,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
        );
      }

      if (i < words.length - 1) spans.add(const TextSpan(text: ' '));
    }

    return RichText(text: TextSpan(children: spans));
  }

  void _showOptionsMenu(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ Only show delete if current user is comment owner
          if (onDelete != null && currentUserId != null && currentUserId == commentOwnerId)
              ListTile(
                leading: Icon(
                  Icons.delete,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Delete Comment',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                onTap: () {
                  Navigator.pop(context);
                  onDelete!();
                },
              ),
            ListTile(
              leading: Icon(
                Icons.flag,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Report Comment',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              onTap: () {
                Navigator.pop(context);
                onReport();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.block,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Block User',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('User blocked'),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
