import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sizer/sizer.dart';
import 'package:skill_link_gh/data/repository/auth_repository.dart';
import 'package:skill_link_gh/provider/profile_provider.dart';
import 'package:skill_link_gh/widgets/custom_app_toast.dart';

import '../../routes/app_routes.dart';
import './widgets/app_logo_section.dart';
import './widgets/login_form_field.dart';
import './widgets/social_login_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isGoogleLoading = false;

  bool _showEmailError = false;
  bool _showPasswordError = false;
  String? _emailErrorText;
  String? _passwordErrorText;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ---------------- VALIDATION ----------------

  void _validateEmail() {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showEmailError = true;
      _emailErrorText = 'Email is required';
    } else if (!RegExp(r'^[\w.-]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showEmailError = true;
      _emailErrorText = 'Enter a valid email';
    } else {
      _showEmailError = false;
      _emailErrorText = null;
    }

    setState(() {});
  }

  void _validatePassword() {
    final password = _passwordController.text;

    if (password.isEmpty) {
      _showPasswordError = true;
      _passwordErrorText = 'Password is required';
    } else if (password.length < 6) {
      _showPasswordError = true;
      _passwordErrorText = 'Minimum 6 characters';
    } else {
      _showPasswordError = false;
      _passwordErrorText = null;
    }

    setState(() {});
  }

  bool _isFormValid() {
    return _emailController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty;
  }

  // ---------------- LOGIN ----------------

  Future<void> _handleLogin() async {
    _validateEmail();
    _validatePassword();

    if (!_isFormValid()) {
      AppToast.show(
        context,
        message: 'Please fix the form errors',
        type: ToastType.error,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check if this email is registered with Google before attempting password sign-in
      final emailQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: _emailController.text.trim())
          .limit(1)
          .get();
      if (emailQuery.docs.isNotEmpty) {
        final provider =
            emailQuery.docs.first.data()['provider'] as String? ?? 'password';
        if (provider == 'google') {
          AppToast.show(
            context,
            message:
                'This account was registered with Google. Please sign in with Google instead.',
            type: ToastType.error,
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final user = FirebaseAuth.instance.currentUser;
      await user?.reload();

      final bool emailVerified = user?.emailVerified ?? false;

      if (!mounted) return;

      // ✅ Show success toast
      AppToast.show(
        context,
        message: 'Login successful',
        type: ToastType.success,
      );

      if (!emailVerified) {
        Navigator.pushReplacementNamed(
          context,
          '/otp-verification-screen',
          arguments: {'email': _emailController.text.trim()},
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/posts-homepage',
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      AppToast.show(
        context,
        message: e.code == 'user-not-found' || e.code == 'wrong-password'
            ? 'Invalid email or password'
            : e.message ?? 'Login failed',
        type: ToastType.error,
      );
    } catch (_) {
      AppToast.show(
        context,
        message: 'Something went wrong. Try again.',
        type: ToastType.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------- GOOGLE ----------------

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);

    try {
      final authRepository = AuthRepository();
      final credential = await authRepository.signInWithGoogle(
        userType: 'artisan',
      );

      if (credential.user == null) {
        throw Exception('Google sign-in returned no user');
      }

      try {
        await FirebaseFunctions.instance.httpsCallable('signInUser').call({
          'email': credential.user!.email,
          'provider': 'google',
        });
      } catch (fnErr) {
        // signInUser function failed but Firebase Auth succeeded — still proceed
        debugPrint('signInUser function error (non-fatal): $fnErr');
      }

      HapticFeedback.mediumImpact();

      if (!mounted) return;
      // Invalidate cached profile so it reloads for the newly signed-in user
      ref.invalidate(profileNotifierProvider);
      Navigator.pushReplacementNamed(context, '/posts-homepage');
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      String msg = 'Google sign-in failed';
      final err = e.toString().toLowerCase();
      if (err.contains('no account found')) {
        msg = e.toString().replaceAll(RegExp(r'Exception:\s*'), '').trim();
      } else if (err.contains('email & password') ||
          err.contains('email and password') ||
          err.contains('already exists') ||
          err.contains('already registered')) {
        msg = e
            .toString()
            .replaceAll(RegExp(r'Exception:\s*(Exception:\s*)?'), '')
            .trim();
      } else if (err.contains('network') || err.contains('socket')) {
        msg = 'No internet connection. Please try again.';
      } else if (err.contains('cancelled') || err.contains('canceled')) {
        msg = 'Sign-in cancelled';
      } else if (err.contains('sign_in_failed') || err.contains('10:')) {
        msg = 'Google sign-in not configured. Check SHA-1 in Firebase.';
      } else if (err.contains('api_not_connected') || err.contains('12500')) {
        msg = 'Google Play Services error. Please update Google Play.';
      }
      if (mounted) {
        AppToast.show(context, message: msg, type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _navigateToRegistration() {
    Navigator.pushNamed(context, AppRoutes.userTypeSelectionScreen);
  }

  // ---------------- FORGOT PASSWORD ----------------

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      AppToast.show(
        context,
        message: 'Please enter your email first',
        type: ToastType.error,
      );
      return;
    }

    if (!RegExp(r'^[\w.-]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      AppToast.show(
        context,
        message: 'Enter a valid email address',
        type: ToastType.error,
      );
      return;
    }

    try {
      // Call Firebase Cloud Function
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
        'resetPassword',
      );
      final result = await callable.call(<String, dynamic>{'email': email});

      if (!mounted) return;

      AppToast.show(
        context,
        message: result.data['message'] ?? 'Password reset link sent',
        type: ToastType.success,
      );
    } on FirebaseFunctionsException catch (e) {
      String msg = 'Failed to send reset email';

      if (e.code == 'not-found') {
        msg = 'No account found with this email';
      } else if (e.code == 'invalid-argument') {
        msg = 'Invalid email address';
      }

      AppToast.show(context, message: msg, type: ToastType.error);
    } catch (_) {
      AppToast.show(
        context,
        message: 'Something went wrong. Try again later.',
        type: ToastType.error,
      );
    }
  }
  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 4.h),
              const AppLogoSection(),
              SizedBox(height: 4.h),

              Text(
                'Welcome Back',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),

              Text(
                'Sign in to continue',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),

              SizedBox(height: 4.h),

              // Email Field
              LoginFormField(
                controller: _emailController,
                label: 'Email',
                hint: 'Enter your email',
                iconName: 'email',
                showError: _showEmailError,
                errorText: _emailErrorText,
                onChanged: () {
                  _showEmailError = false;
                  setState(() {});
                },
              ),

              SizedBox(height: 2.h),

              // Password Field with Forgot Password
              LoginFormField(
                controller: _passwordController,
                label: 'Password',
                hint: 'Enter your password',
                iconName: 'lock',
                isPassword: true,
                showError: _showPasswordError,
                errorText: _passwordErrorText,
                onChanged: () {
                  _showPasswordError = false;
                  setState(() {});
                },
                onForgotPassword: _handleForgotPassword, // ✅ Correctly placed
              ),

              SizedBox(height: 2.h),

              SizedBox(
                height: 6.h, // responsive height
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        50,
                      ), // circular/pill shape
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    elevation: 6,
                    shadowColor: Theme.of(context).shadowColor.withOpacity(0.3),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.onPrimary,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Login',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                ),
              ),

              SizedBox(height: 3.h),

              Row(
                children: [
                  Expanded(
                    child: SocialLoginButton(
                      provider: 'Google',
                      icon: FontAwesomeIcons.google,
                      iconColor: Colors.redAccent,
                      onTap: _handleGoogleSignIn,
                      isLoading: _isGoogleLoading,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 3.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('New user? '),
                  TextButton(
                    onPressed: _navigateToRegistration,
                    child: const Text('Sign Up'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
