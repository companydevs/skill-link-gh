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
    final rating = (artisanData['rating'] as num?)?.toDouble() ?? 0.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
      child: Row(
        children: [
          _StatCard(
            value: '$jobsDone',
            label: 'Jobs Done',
            icon: Icons.check_circle_outline_rounded,
            iconColor: const Color(0xFF10B981),
            theme: theme,
          ),
          SizedBox(width: 2.w),
          _StatCard(
            value: '$bidsAccepted',
            label: 'Bids Won',
            icon: Icons.handshake_outlined,
            iconColor: const Color(0xFF2563EB),
            theme: theme,
          ),
          SizedBox(width: 2.w),
          _StatCard(
            value: rating > 0 ? rating.toStringAsFixed(1) : '—',
            label: 'Rating',
            icon: Icons.star_rounded,
            iconColor: const Color(0xFFF59E0B),
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;
  final ThemeData theme;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.5.h, horizontal: 2.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: iconColor),
            SizedBox(height: 0.6.h),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 0.2.h),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
