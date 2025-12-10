import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// About section widget displaying artisan bio and details
class AboutSectionWidget extends StatelessWidget {
  final Map<String, dynamic> artisanData;

  const AboutSectionWidget({
    super.key,
    required this.artisanData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bio Section
          Text(
            'About',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            artisanData["bio"] as String,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
            ),
          ),
          SizedBox(height: 3.h),
          // Experience
          _buildInfoRow(
            context,
            icon: 'work_history',
            label: 'Experience',
            value: artisanData["experience"] as String,
          ),
          SizedBox(height: 2.h),
          // Location
          _buildInfoRow(
            context,
            icon: 'location_on',
            label: 'Location',
            value: artisanData["location"] as String,
          ),
          SizedBox(height: 2.h),
          // Member Since
          _buildInfoRow(
            context,
            icon: 'calendar_today',
            label: 'Member Since',
            value: _formatDate(artisanData["memberSince"] as String),
          ),
          SizedBox(height: 2.h),
          // Languages
          _buildInfoRow(
            context,
            icon: 'language',
            label: 'Languages',
            value: (artisanData["languages"] as List).join(', '),
          ),
          SizedBox(height: 3.h),
          // Certifications
          Text(
            'Certifications',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          ...(artisanData["certifications"] as List).map((cert) => Padding(
                padding: EdgeInsets.only(bottom: 1.5.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 0.5.h),
                      padding: EdgeInsets.all(1.w),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: CustomIconWidget(
                        iconName: 'verified',
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Text(
                        cert as String,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )),
          SizedBox(height: 3.h),
          // Verification Badges
          Text(
            'Verification Status',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          _buildVerificationBadge(
            context,
            icon: 'badge',
            label: 'Identity Verified',
            verified: (artisanData["verificationBadges"]
                as Map)["identityVerified"] as bool,
          ),
          SizedBox(height: 1.5.h),
          _buildVerificationBadge(
            context,
            icon: 'workspace_premium',
            label: 'Skill Certified',
            verified: (artisanData["verificationBadges"]
                as Map)["skillCertified"] as bool,
          ),
          SizedBox(height: 1.5.h),
          _buildVerificationBadge(
            context,
            icon: 'security',
            label: 'Background Checked',
            verified: (artisanData["verificationBadges"]
                as Map)["backgroundChecked"] as bool,
          ),
          SizedBox(height: 10.h),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomIconWidget(
          iconName: icon,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationBadge(
    BuildContext context, {
    required String icon,
    required String label,
    required bool verified,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: verified
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: verified
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: icon,
            size: 24,
            color: verified
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: verified
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
          if (verified)
            CustomIconWidget(
              iconName: 'check_circle',
              size: 20,
              color: theme.colorScheme.primary,
            ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}
