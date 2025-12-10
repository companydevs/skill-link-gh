import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Profile statistics widget showing key metrics
class ProfileStatsWidget extends StatelessWidget {
  final Map<String, dynamic> artisanData;

  const ProfileStatsWidget({
    super.key,
    required this.artisanData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.only(top: 10.h, left: 4.w, right: 4.w, bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            context,
            icon: 'work',
            value: '${artisanData["totalJobs"]}',
            label: 'Jobs Done',
          ),
          Container(
            width: 1,
            height: 6.h,
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
          _buildStatItem(
            context,
            icon: 'schedule',
            value: artisanData["responseTime"] as String,
            label: 'Response',
          ),
          Container(
            width: 1,
            height: 6.h,
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
          _buildStatItem(
            context,
            icon: 'location_on',
            value: (artisanData["location"] as String).split(',')[0],
            label: 'Location',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String icon,
    required String value,
    required String label,
  }) {
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
        children: [
          CustomIconWidget(
            iconName: icon,
            size: 24,
            color: theme.colorScheme.primary,
          ),
          SizedBox(height: 1.h),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
