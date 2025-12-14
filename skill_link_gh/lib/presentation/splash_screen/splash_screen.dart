import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();

    // Fade-in animation
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) setState(() => _isVisible = true);
    });

    // Navigate after splash delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.onboardingScreen,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            theme.brightness == Brightness.dark
                ? Brightness.light
                : Brightness.dark,
        systemNavigationBarColor: colorScheme.surface,
        systemNavigationBarIconBrightness:
            theme.brightness == Brightness.dark
                ? Brightness.light
                : Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: AnimatedOpacity(
        opacity: _isVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        child: Stack(
          children: [
            /// CENTER CONTENT
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// LOGO (NO COLOR OVERLAY)
                  Image.asset(
                    'assets/images/skill_link.png',
                    width: 48.w,
                    fit: BoxFit.contain,
                  ),

                  SizedBox(height: 3.h),

                  /// TAGLINE
                  Text(
                    'Connect with Skilled Artisans',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            /// PROFESSIONAL DOT LOADER
            Positioned(
              bottom: 6.h,
              left: 0,
              right: 0,
              child: Center(
                child: LoadingAnimationWidget.staggeredDotsWave(
                  color: colorScheme.primary,
                  size: 34,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
