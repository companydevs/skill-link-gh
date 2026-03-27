import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ProfileStatsWidget extends StatelessWidget {
  final Map<String, dynamic> artisanData;

  const ProfileStatsWidget({super.key, required this.artisanData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalJobs = artisanData['totalJobs'] ?? 0;
    final responseTime = artisanData['responseTime'] as String? ?? 'N/A';
    final experience = artisanData['experience'] as String? ?? 'N/A';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        children: [
          _stat(context, '$totalJobs', 'Jobs', theme),
          _divider(theme),
          _stat(context, responseTime, 'Response', theme),
          _divider(theme),
          _stat(context, experience, 'Experience', theme),
        ],
      ),
    );
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
