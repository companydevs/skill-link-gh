import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class VerificationStatusWidget extends StatelessWidget {
  final Map<String, dynamic> artisanData;
  final VoidCallback onVerifyTap;

  const VerificationStatusWidget({
    super.key,
    required this.artisanData,
    required this.onVerifyTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verificationBadges =
        artisanData["verificationBadges"] as Map<String, dynamic>?;
    final isIdentityVerified = verificationBadges?["identityVerified"] == true;
    final isBusinessVerified = verificationBadges?["businessVerified"] == true;
    final isSkillVerified = verificationBadges?["skillVerified"] == true;

    // If fully verified, don't show this widget
    if (isIdentityVerified && isBusinessVerified && isSkillVerified) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and title
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CustomIconWidget(
                  iconName: 'verified_user',
                  size: 28,
                  color: theme.colorScheme.primary,
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Get Verified',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'Increase your bookings by up to 3x',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 3.h),

          // Benefits section
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildBenefitItem(
                  theme,
                  'Higher search ranking',
                  Icons.trending_up,
                ),
                _buildBenefitItem(theme, 'More client trust', Icons.favorite),
                _buildBenefitItem(theme, 'Premium badge display', Icons.star),
              ],
            ),
          ),

          SizedBox(height: 3.h),

          // Verification checklist
          Text(
            'Verification Steps',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.5.h),

          _buildVerificationItem(
            theme,
            'Identity Verification',
            isIdentityVerified,
            'Verify with government ID',
            Icons.person_outline,
            isRequired: true,
          ),

          _buildVerificationItem(
            theme,
            'Business Verification',
            isBusinessVerified,
            'Business registration (optional)',
            Icons.business_outlined,
          ),

          _buildVerificationItem(
            theme,
            'Skill Verification',
            isSkillVerified,
            'Upload certificates (optional)',
            Icons.school_outlined,
          ),

          SizedBox(height: 3.h),

          // Get Verified Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onVerifyTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: 'verified_user',
                    size: 20,
                    color: Colors.white,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Start Verification',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
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

  Widget _buildBenefitItem(ThemeData theme, String text, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.8.h),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          SizedBox(width: 3.w),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationItem(
    ThemeData theme,
    String title,
    bool isVerified,
    String description,
    IconData icon, {
    bool isRequired = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: isVerified
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isVerified
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: isVerified
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isVerified ? Icons.check : icon,
              size: 20,
              color: isVerified
                  ? Colors.white
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isVerified
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    if (isRequired) ...[
                      SizedBox(width: 2.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 1.5.w,
                          vertical: 0.3.h,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Required',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 0.3.h),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (isVerified)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.8.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Verified',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
