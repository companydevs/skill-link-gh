import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Simple App Logo Section without any wave
class AppLogoSection extends StatelessWidget {
  const AppLogoSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 8.h), // top spacing
        Image.asset(
          'assets/images/skill_link.png',
          width: 50.w, // half of screen width
          height: 25.w, // proportional height
          fit: BoxFit.contain,
        ),
        SizedBox(height: 2.h),
        Text(
          'Connect with skilled artisans',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
