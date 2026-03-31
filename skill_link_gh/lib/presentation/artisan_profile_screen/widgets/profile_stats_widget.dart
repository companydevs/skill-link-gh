import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ProfileStatsWidget extends StatelessWidget {
  final Map<String, dynamic> artisanData;
  final int followersCount;
  final int followingCount;
  final int postsCount;

  const ProfileStatsWidget({
    super.key,
    required this.artisanData,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        children: [
          _stat(context, '$postsCount', 'Posts', theme),
          _divider(theme),
          _stat(context, _formatCount(followersCount), 'Followers', theme),
          _divider(theme),
          _stat(context, _formatCount(followingCount), 'Following', theme),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }

  Widget _stat(
    BuildContext context,
    String value,
    String label,
    ThemeData theme,
  ) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 0.3.h),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _divider(ThemeData theme) => Container(
    width: 1,
    height: 4.h,
    color: theme.colorScheme.outline.withValues(alpha: 0.25),
  );
}
