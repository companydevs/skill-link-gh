import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Social registration options widget using FontAwesome icons
class SocialRegistrationWidget extends StatelessWidget {
  final VoidCallback onGoogleSignIn;
  final VoidCallback onAppleSignIn;

  const SocialRegistrationWidget({
    super.key,
    required this.onGoogleSignIn,
    required this.onAppleSignIn,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Divider with text
        Row(
          children: [
            Expanded(child: Divider(color: theme.dividerColor)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                'Or continue with',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(child: Divider(color: theme.dividerColor)),
          ],
        ),

        SizedBox(height: 3.h),

        // Social buttons
        Row(
          children: [
            // Google button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onGoogleSignIn,
                icon: FaIcon(
                  FontAwesomeIcons.google,
                  color: null, // multicolor icon, will render default colors
                  size: 24,
                ),
                label: Text(
                  'Google',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 1.8.h),
                  side: BorderSide(color: theme.dividerColor, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            SizedBox(width: 3.w),

            // Apple button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onAppleSignIn,
                icon: FaIcon(
                  FontAwesomeIcons.apple,
                  color: theme.colorScheme.onSurface,
                  size: 24,
                ),
                label: Text(
                  'Apple',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 1.8.h),
                  side: BorderSide(color: theme.dividerColor, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
