import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      if (!mounted) return;
      _checkUserStatusAndNavigate();
    });
  }

 Future<void> _checkUserStatusAndNavigate() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    Navigator.pushReplacementNamed(context, AppRoutes.onboardingScreen);
    return;
  }

  try {
    await user.reload();

    final response = await FirebaseFunctions.instance
        .httpsCallable('checkUserStatus')
        .call({'uid': user.uid});

    final data = response.data as Map<String, dynamic>;
    final bool emailVerified = data['emailVerified'] ?? false;
    final bool isOtpVerified = data['isOtpVerified'] ?? false;

    if (emailVerified && isOtpVerified) {
      Navigator.pushReplacementNamed(context, AppRoutes.postsHomepage);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.loginScreen);
    }
  } on FirebaseFunctionsException catch (e) {
    if (e.code == 'unavailable' ||
        e.code == 'deadline-exceeded') {
      _showNoInternetDialog();
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.postsHomepage);
    }
  } catch (_) {
    // Network error / socket error
    _showNoInternetDialog();
  }
}
void _showNoInternetDialog() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;

      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.wifi_off, color: colorScheme.error),
            const SizedBox(width: 8),
            const Text("No Internet"),
          ],
        ),
        content: const Text(
          "Please check your internet connection and try again.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Just close
            },
            child: const Text("OK"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _checkUserStatusAndNavigate(); // Retry
            },
            child: const Text("Retry"),
          ),
        ],
      );
    },
  );
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
                  /// LOGO
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

            /// LOADER
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
