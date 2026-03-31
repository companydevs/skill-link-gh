import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ProfileStatsWidget extends StatelessWidget {
  final Map<String, dynamic> artisanData;
  final int jobsDone;
  final int bidsAccepted;
  final int postsCount;

  const ProfileStatsWidget({
    super.key,
    required this.artisanData,
    this.jobsDone = 0,
    this.bidsAccepted = 0,
    this.postsCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Transform.translate(
      offset: const Offset(0, -12),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 1.4.h),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              _stat('$jobsDone', 'Jobs Done', theme),
              _vDivider(theme),
              _stat('$bidsAccepted', 'Bids Won', theme),
              _vDivider(theme),
              _stat('$postsCount', 'Posts', theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String value, String label, ThemeData theme) => Expanded(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
      ],
    ),
  );

  Widget _vDivider(ThemeData theme) => Container(
    width: 1,
    height: 32,
    color: theme.colorScheme.outline.withValues(alpha: 0.15),
  );
}
