import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

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
    final badges = artisanData['verificationBadges'] as Map?;
    final isIdentityVerified = badges?['identityVerified'] == true;

    if (isIdentityVerified) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: InkWell(
        onTap: onVerifyTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  'Get verified to boost your bookings',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
