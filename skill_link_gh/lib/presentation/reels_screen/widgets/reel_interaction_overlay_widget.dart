import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Interaction overlay widget for reels
/// Displays like, comment, share, and book service buttons
class ReelInteractionOverlayWidget extends StatelessWidget {
  final int likes;
  final int comments;
  final int shares;
  final bool isLiked;
  final VoidCallback onLikeTap;
  final VoidCallback onCommentTap;
  final VoidCallback onShareTap;
  final VoidCallback onBookServiceTap;

  const ReelInteractionOverlayWidget({
    super.key,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.isLiked,
    required this.onLikeTap,
    required this.onCommentTap,
    required this.onShareTap,
    required this.onBookServiceTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildInteractionButton(
          icon: isLiked ? 'favorite' : 'favorite_border',
          label: _formatCount(likes),
          color: isLiked ? Colors.red : Colors.white,
          onTap: onLikeTap,
        ),
        const SizedBox(height: 24),
        _buildInteractionButton(
          icon: 'chat_bubble_outline',
          label: _formatCount(comments),
          color: Colors.white,
          onTap: onCommentTap,
        ),
        const SizedBox(height: 24),
        _buildInteractionButton(
          icon: 'share',
          label: _formatCount(shares),
          color: Colors.white,
          onTap: onShareTap,
        ),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: onBookServiceTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: 'calendar_today',
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Book',
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildInteractionButton({
    required String icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(
            iconName: icon,
            color: color,
            size: 32,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
