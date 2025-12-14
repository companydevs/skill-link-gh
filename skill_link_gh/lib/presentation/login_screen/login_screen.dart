import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sizer/sizer.dart';

import '../../routes/app_routes.dart';
import './widgets/app_logo_section.dart';
import './widgets/login_form_field.dart';
import './widgets/social_login_button.dart';

/// Login screen for SkillLink application
/// Provides email/password authentication and social login options
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _showEmailError = false;
  bool _showPasswordError = false;
  String? _emailErrorText;
  String? _passwordErrorText;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;
  bool _isFacebookLoading = false;

  // Mock credentials for testing
  final String _mockEmail = 'artisan@skilllink.com';
  final String _mockPassword = 'Artisan@123';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateEmail() {
    setState(() {
      final email = _emailController.text.trim();
      if (email.isEmpty) {
        _showEmailError = true;
        _emailErrorText = 'Email is required';
      } else if (!RegExp(
        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}\$',
      ).hasMatch(email)) {
        _showEmailError = true;
        _emailErrorText = 'Please enter a valid email address';
      } else {
        _showEmailError = false;
        _emailErrorText = null;
      }
    });
  }

  void _validatePassword() {
    setState(() {
      final password = _passwordController.text;
      if (password.isEmpty) {
        _showPasswordError = true;
        _passwordErrorText = 'Password is required';
      } else if (password.length < 6) {
        _showPasswordError = true;
        _passwordErrorText = 'Password must be at least 6 characters';
      } else {
        _showPasswordError = false;
        _passwordErrorText = null;
      }
    });
  }

  bool _isFormValid() {
    return _emailController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        !_showEmailError &&
        !_showPasswordError;
  }

  Future<void> _handleLogin() async {
    _validateEmail();
    _validatePassword();

    if (!_isFormValid()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate authentication delay
    await Future.delayed(const Duration(seconds: 2));

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email == _mockEmail && password == _mockPassword) {
      // Success - trigger haptic feedback
      HapticFeedback.mediumImpact();

      if (mounted) {
        // Navigate to artisan profile screen
        Navigator.pushReplacementNamed(context, '/artisan-profile-screen');
      }
    } else {
      // Show error message
      if (mounted) {
        setState(() {
          _isLoading = false;
          _showEmailError = true;
          _showPasswordError = true;
          _emailErrorText = 'Invalid credentials';
          _passwordErrorText = 'Please check your email and password';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Invalid credentials. Use: $_mockEmail / $_mockPassword',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isGoogleLoading = false;
      });

      HapticFeedback.mediumImpact();
      Navigator.pushReplacementNamed(context, '/artisan-profile-screen');
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() {
      _isAppleLoading = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isAppleLoading = false;
      });

      HapticFeedback.mediumImpact();
      Navigator.pushReplacementNamed(context, '/artisan-profile-screen');
    }
  }

  Future<void> _handleFacebookSignIn() async {
    setState(() {
      _isFacebookLoading = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isFacebookLoading = false;
      });

      HapticFeedback.mediumImpact();
      Navigator.pushReplacementNamed(context, '/artisan-profile-screen');
    }
  }

  void _handleForgotPassword() {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final resetEmailController = TextEditingController();

        return AlertDialog(
          title: Text('Reset Password', style: theme.textTheme.titleLarge),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your email address and we\'ll send you a link to reset your password.',
                style: theme.textTheme.bodyMedium,
              ),
              SizedBox(height: 2.h),
              TextField(
                controller: resetEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Password reset link sent to your email'),
                    backgroundColor: theme.colorScheme.primary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Text('Send Link'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToRegistration() {
    Navigator.pushNamed(context, AppRoutes.userTypeSelectionScreen);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 4.h),

                    // App Logo Section
                    const AppLogoSection(),

                    SizedBox(height: 4.h),

                    // Welcome Text
                    Text(
                      'Welcome Back',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Sign in to continue to your account',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 4.h),

                    // Email Field
                    LoginFormField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'Enter your email',
                      iconName: 'email',
                      keyboardType: TextInputType.emailAddress,
                      showError: _showEmailError,
                      errorText: _emailErrorText,
                      onChanged: () {
                        if (_showEmailError) {
                          setState(() {
                            _showEmailError = false;
                            _emailErrorText = null;
                          });
                        }
                      },
                    ),

                    SizedBox(height: 2.h),

                    // Password Field
                    LoginFormField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'Enter your password',
                      iconName: 'lock',
                      isPassword: true,
                      showError: _showPasswordError,
                      errorText: _passwordErrorText,
                      onChanged: () {
                        if (_showPasswordError) {
                          setState(() {
                            _showPasswordError = false;
                            _passwordErrorText = null;
                          });
                        }
                      },
                    ),

                    SizedBox(height: 1.h),

                    // Forgot Password Link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _handleForgotPassword,
                        child: Text(
                          'Forgot Password?',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 2.h),

                    // Login Button
                    SizedBox(
                      height: 6.h,
                      child: ElevatedButton(
                        onPressed:
                            _isLoading || !_isFormValid() ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          disabledBackgroundColor: theme.colorScheme.primary
                              .withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child:
                            _isLoading
                                ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      theme.colorScheme.onPrimary,
                                    ),
                                  ),
                                )
                                : Text(
                                  'Login',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                      ),
                    ),

                    SizedBox(height: 3.h),

                    // Divider with text
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: theme.colorScheme.outline.withValues(
                              alpha: 0.3,
                            ),
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          child: Text(
                            'Or continue with',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: theme.colorScheme.outline.withValues(
                              alpha: 0.3,
                            ),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 3.h),

                    // Social Login Buttons
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
    SizedBox(width: 3.w),
    Expanded(
      child: SocialLoginButton(
        provider: 'Apple',
        icon: FontAwesomeIcons.apple,
        iconColor: Colors.black,
        onTap: _handleAppleSignIn,
        isLoading: _isAppleLoading,
      ),
    ),
  ],
),

                

                    SizedBox(height: 3.h),

                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'New user? ',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _navigateToRegistration,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Sign Up',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 2.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
