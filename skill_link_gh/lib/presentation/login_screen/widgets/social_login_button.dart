import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Social login button widget for OAuth providers
class SocialLoginButton extends StatelessWidget {
  final String provider;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final bool isLoading;

  const SocialLoginButton({
    super.key,
    required this.provider,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      height: 6.h,
      child: OutlinedButton(
        onPressed: isLoading ? null : onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: theme.colorScheme.surface,
          side: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(
                    theme.colorScheme.primary,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(
                    icon,
                    size: 22,
                    color: iconColor,
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    provider,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
