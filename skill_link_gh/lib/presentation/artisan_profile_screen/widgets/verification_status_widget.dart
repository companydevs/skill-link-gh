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
    final isVerified = badges?['identityVerified'] == true;

    if (isVerified) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 1.5.h),
      child: GestureDetector(
        onTap: onVerifyTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shield_outlined,
              size: 14,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 5),
            Text(
              'Get verified',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              '· boost your bookings',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
