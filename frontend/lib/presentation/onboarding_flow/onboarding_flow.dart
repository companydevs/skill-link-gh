import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../widgets/custom_image_widget.dart';

/// Onboarding Flow screen for SkillLink artisan marketplace
/// Introduces new users to key features through swipeable screens
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _introKey = GlobalKey<IntroductionScreenState>();
  bool _isLastPage = false;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  /// Check if user has already completed onboarding
  Future<void> _checkOnboardingStatus() async {
    // In production, check SharedPreferences for onboarding completion
    // For now, we'll show onboarding every time
  }

  /// Mark onboarding as completed
  Future<void> _completeOnboarding() async {
    // In production, save to SharedPreferences
    // await prefs.setBool('onboarding_completed', true);
  }

  /// Navigate to registration screen
  void _navigateToRegistration() {
    Navigator.pushReplacementNamed(context, AppRoutes.userTypeSelectionScreen);
  }

  /// Navigate to login screen
  void _navigateToLogin() {
    _completeOnboarding();
    Navigator.pushReplacementNamed(context, '/login-screen');
  }

  /// Skip onboarding and go to registration
  void _skipOnboarding() {
    _navigateToRegistration();
  }

  /// Build page decoration with consistent styling
  PageDecoration _buildPageDecoration(ThemeData theme) {
    return PageDecoration(
      titleTextStyle: theme.textTheme.headlineLarge!.copyWith(
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurface,
        height: 1.2,
      ),
      bodyTextStyle: theme.textTheme.bodyLarge!.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
        height: 1.5,
      ),
      imagePadding: EdgeInsets.zero,
      contentMargin: const EdgeInsets.symmetric(horizontal: 24),
      titlePadding: const EdgeInsets.only(top: 32, bottom: 16),
      bodyPadding: const EdgeInsets.symmetric(horizontal: 16),
      pageColor: theme.scaffoldBackgroundColor,
      imageFlex: 3,
      bodyFlex: 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: IntroductionScreen(
          key: _introKey,
          pages: [
            // Page 1: Connect with Skilled Artisans
            PageViewModel(
              title: "Connect with Skilled Artisans",
              body:
                  "Discover and connect with verified professional artisans in your area. From carpenters to electricians, find the right expert for your project.",
              image: Center(
                child: CustomImageWidget(
                  imageUrl:
                      "https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=800&q=80",
                  width: double.infinity,
                  height: 400,
                  fit: BoxFit.cover,
                  semanticLabel:
                      "Professional carpenter working on wooden furniture in a well-lit workshop with tools and materials visible in the background",
                ),
              ),
              decoration: _buildPageDecoration(theme),
            ),

            // Page 2: Real-time Messaging
            PageViewModel(
              title: "Real-time Messaging",
              body:
                  "Chat directly with artisans to discuss your project details, get quotes, and schedule appointments. Stay connected throughout your project.",
              image: Center(
                child: CustomImageWidget(
                  imageUrl:
                      "https://images.unsplash.com/photo-1577563908411-5077b6dc7624?w=800&q=80",
                  width: double.infinity,
                  height: 400,
                  fit: BoxFit.cover,
                  semanticLabel:
                      "Close-up of hands holding a smartphone displaying a messaging app interface with chat bubbles and conversation threads",
                ),
              ),
              decoration: _buildPageDecoration(theme),
            ),

            // Page 3: Portfolio Discovery
            PageViewModel(
              title: "Explore Portfolios",
              body:
                  "Browse through detailed portfolios showcasing artisans' previous work. View ratings, reviews, and completed projects to make informed decisions.",
              image: Center(
                child: CustomImageWidget(
                  imageUrl:
                      "https://images.unsplash.com/photo-1542744173-8e7e53415bb0?w=800&q=80",
                  width: double.infinity,
                  height: 400,
                  fit: BoxFit.cover,
                  semanticLabel:
                      "Professional business team reviewing project portfolio on a tablet device in a modern office setting with natural lighting",
                ),
              ),
              decoration: _buildPageDecoration(theme),
            ),
          ],
          onDone: () {
            setState(() => _isLastPage = true);
          },
          onSkip: _skipOnboarding,
          showSkipButton: true,
          skip: Text(
            'Skip',
            style: theme.textTheme.labelLarge!.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          next: CustomIconWidget(
            iconName: 'arrow_forward',
            color: theme.colorScheme.primary,
            size: 24,
          ),
          done: Text(
            'Done',
            style: theme.textTheme.labelLarge!.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          dotsDecorator: DotsDecorator(
            size: const Size.square(10.0),
            activeSize: const Size(24.0, 10.0),
            activeColor: theme.colorScheme.primary,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            spacing: const EdgeInsets.symmetric(horizontal: 4.0),
            activeShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.0),
            ),
          ),
          globalBackgroundColor: theme.scaffoldBackgroundColor,
          skipOrBackFlex: 0,
          nextFlex: 0,
          curve: Curves.easeInOut,
          controlsMargin: const EdgeInsets.all(16),
          controlsPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          onChange: (index) {
            setState(() => _isLastPage = index == 2);
          },
        ),
      ),
      bottomNavigationBar:
          _isLastPage
              ? Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withValues(alpha: 0.08),
                      offset: const Offset(0, -2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Sign Up Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _navigateToRegistration,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Sign Up',
                            style: theme.textTheme.labelLarge!.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: _navigateToLogin,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.primary,
                            side: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Login',
                            style: theme.textTheme.labelLarge!.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : null,
    );
  }
}
