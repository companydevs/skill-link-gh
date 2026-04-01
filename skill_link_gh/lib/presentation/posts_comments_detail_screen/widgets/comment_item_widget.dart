import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CommentItemWidget extends StatelessWidget {
  final String commentId;
  final String commentOwnerId;
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
    required this.commentOwnerId,
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
    final theme = Theme.of(context);
    final indent = level * 40.0;

    return Padding(
      padding: EdgeInsets.only(left: indent, right: 0, top: 4, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avatar ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(left: 14, right: 10, top: 2),
            child: CircleAvatar(
              radius: level == 0 ? 18 : 14,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              backgroundImage: CachedNetworkImageProvider(userAvatar),
            ),
          ),

          // ── Content ───────────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username + text inline (Instagram style)
                RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium,
                    children: [
                      TextSpan(
                        text: '$userName  ',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      ..._buildTextSpans(context, commentText),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                // Timestamp · Reply · Hide
                Row(
                  children: [
                    Text(
                      timestamp,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    if (likes > 0) ...[
                      const SizedBox(width: 10),
                      Text(
                        '$likes ${likes == 1 ? 'like' : 'likes'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: onReply,
                      child: Text(
                        'Reply',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (onDelete != null) ...[
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: onDelete,
                        child: Text(
                          'Delete',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                // View replies
                if (replies > 0 && onToggleReplies != null) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: onToggleReplies,
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 1,
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.4,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'View $replies ${replies == 1 ? 'reply' : 'replies'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Heart (right side, Instagram style) ───────────────────────────
          Padding(
            padding: const EdgeInsets.only(right: 14, top: 2),
            child: GestureDetector(
              onTap: onLike,
              child: Column(
                children: [
                  Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                    color: isLiked
                        ? const Color(0xFFED4956)
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  if (likes > 0)
                    Text(
                      '$likes',
                      style: TextStyle(
                        fontSize: 10,
                        color: isLiked
                            ? const Color(0xFFED4956)
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<TextSpan> _buildTextSpans(BuildContext context, String text) {
    final theme = Theme.of(context);
    final spans = <TextSpan>[];
    final words = text.split(' ');
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      if (word.startsWith('@') || word.startsWith('#')) {
        spans.add(
          TextSpan(
            text: word,
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      } else {
        spans.add(TextSpan(text: word));
      }
      if (i < words.length - 1) spans.add(const TextSpan(text: ' '));
    }
    return spans;
  }

  void _showOptionsMenu(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onDelete != null &&
                currentUserId != null &&
                currentUserId == commentOwnerId)
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: theme.colorScheme.error,
                ),
                title: Text(
                  'Delete',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onDelete!();
                },
              ),
            ListTile(
              leading: Icon(
                Icons.flag_outlined,
                color: theme.colorScheme.onSurface,
              ),
              title: const Text('Report'),
              onTap: () {
                Navigator.pop(context);
                onReport();
              },
            ),
          ],
        ),
      ),
    );
  }
}
