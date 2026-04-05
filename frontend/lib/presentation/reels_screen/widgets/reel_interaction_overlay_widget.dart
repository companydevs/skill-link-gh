import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../widgets/custom_icon_widget.dart';

/// Right-side action buttons — Instagram Reels style
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Like
        _ActionBtn(
          onTap: onLikeTap,
          label: _fmt(likes),
          child: Icon(
            isLiked ? Icons.favorite : Icons.favorite_border,
            color: isLiked ? Colors.red : Colors.white,
            size: 30,
          ),
        ),
        const SizedBox(height: 20),

        // Comment — uses same SVG as post card
        _ActionBtn(
          onTap: onCommentTap,
          label: _fmt(comments),
          child: SvgPicture.asset(
            'assets/images/comment-1-svgrepo-com.svg',
            width: 28,
            height: 28,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
        ),
        const SizedBox(height: 20),

        // Share
        _ActionBtn(
          onTap: onShareTap,
          label: _fmt(shares),
          child: SvgPicture.asset(
            'assets/images/send-svgrepo-com.svg',
            width: 28,
            height: 28,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
        ),
        const SizedBox(height: 24),

        // Book — compact pill button
        GestureDetector(
          onTap: onBookServiceTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomIconWidget(
                  iconName: 'calendar_today',
                  color: Colors.black,
                  size: 16,
                ),
                const SizedBox(width: 4),
                const Text(
                  'Book',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _ActionBtn extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final Widget child;

  const _ActionBtn({
    required this.onTap,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          child,
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }
}
