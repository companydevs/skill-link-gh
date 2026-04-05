// lib/presentation/registration/registration_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';
import 'package:skill_link_gh/data/repository/auth_repository.dart';
import 'package:skill_link_gh/domain/models/userTypes.dart';
import 'package:skill_link_gh/provider/registration_provider.dart';
import 'package:skill_link_gh/widgets/custom_app_toast.dart';
import 'package:skill_link_gh/widgets/custom_error_handler.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/registration_form_widget.dart';
import './widgets/social_registration_widget.dart';
import './widgets/terms_agreement_widget.dart';
import '../../domain/models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _businessDescriptionController =
      TextEditingController();

  final FocusNode _fullNameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();
  final FocusNode _businessNameFocus = FocusNode();
  final FocusNode _businessDescriptionFocus = FocusNode();
  late UserType _userType;

  bool _isAgreedToTerms = false;
  bool _isGoogleLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is String) {
      _userType = (args == 'artisan') ? UserType.artisan : UserType.client;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _businessNameController.dispose();
    _businessDescriptionController.dispose();
    _fullNameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _businessNameFocus.dispose();
    _businessDescriptionFocus.dispose();
    super.dispose();
  }

  Future<void> _handleRegistration() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      AppToast.show(
        context,
        message: 'Please fix the errors in the form',
        type: ToastType.error,
      );

      return;
    }

    if (!_isAgreedToTerms) {
      Fluttertoast.showToast(
        msg: 'Please agree to Terms of Service and Privacy Policy',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP_RIGHT,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 14.sp,
      );
      return;
    }

    final user = UserModel(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: normalizePhoneNumber(_phoneController.text),
      password: _passwordController.text.trim(),
      userType: _userType, // enum

      businessName: _businessNameController.text.trim(),
      businessDescription: _businessDescriptionController.text.trim(),
    );

    bool goToOtp = false;

    await ErrorHandler.runWithLoader(
      context: context,
      action: () async {
        final authRepository = AuthRepository();
        final result = await authRepository.registerUser(user);

        goToOtp = !(result['isVerified'] as bool? ?? false);
      },
      successMessage: 'Registration successful!',
    );

    if (!mounted) return;

    // ✅ NAVIGATE AFTER LOADER IS CLOSED
    if (goToOtp) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.otpVerificationScreen,
        arguments: {'email': user.email, 'userType': _userType},
      );
    } else {
      Navigator.pushReplacementNamed(context, '/login-screen');
    }
  }

  String normalizePhoneNumber(String input) {
    String phone = input.trim().replaceAll(' ', '');

    // Already international
    if (phone.startsWith('+')) {
      return phone;
    }

    // Ghana numbers
    if (phone.startsWith('0')) {
      return '+233${phone.substring(1)}';
    }

    // If user typed without 0 (e.g. 551234567)
    if (phone.length == 9) {
      return '+233$phone';
    }

    return phone; // fallback
  }

  void _navigateToLogin() =>
      Navigator.pushReplacementNamed(context, '/login-screen');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(registrationProvider);
    final isArtisan = _userType == 'artisan';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: theme.colorScheme.onSurface,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Create Account', style: theme.textTheme.titleLarge),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Join SkillLink',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      isArtisan
                          ? 'Create your artisan profile and connect with clients'
                          : 'Create your account to find skilled artisans',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    RegistrationFormWidget(
                      formKey: _formKey,
                      fullNameController: _fullNameController,
                      emailController: _emailController,
                      phoneController: _phoneController,
                      passwordController: _passwordController,
                      confirmPasswordController: _confirmPasswordController,
                      businessNameController: _businessNameController,
                      businessDescriptionController:
                          _businessDescriptionController,
                      fullNameFocus: _fullNameFocus,
                      emailFocus: _emailFocus,
                      phoneFocus: _phoneFocus,
                      passwordFocus: _passwordFocus,
                      confirmPasswordFocus: _confirmPasswordFocus,
                      businessNameFocus: _businessNameFocus,
                      businessDescriptionFocus: _businessDescriptionFocus,
                      isArtisan: _userType == UserType.artisan,
                    ),
                    SizedBox(height: 3.h),
                    TermsAgreementWidget(
                      isAgreed: _isAgreedToTerms,
                      onChanged: (value) =>
                          setState(() => _isAgreedToTerms = value ?? false),
                    ),
                    SizedBox(height: 3.h),
                    ElevatedButton(
                      onPressed: state.isLoading ? null : _handleRegistration,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: state.isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : Text(
                              'Create Account',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                    ),
                    SizedBox(height: 3.h),
                    if (state.errorMessage != null)
                      Text(
                        state.errorMessage!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.red,
                        ),
                      ),
                    SizedBox(height: 3.h),
                    SocialRegistrationWidget(
                      onGoogleSignIn: () async {
                        final authRepository = AuthRepository();
                        setState(() => _isGoogleLoading = true);
                        try {
                          final userCredential = await authRepository
                              .signUpWithGoogle(userType: _userType.name);
                          if (!mounted) return;
                          if (userCredential.user != null) {
                            Navigator.pushReplacementNamed(
                              context,
                              '/posts-homepage',
                            );
                          }
                        } catch (e) {
                          String msg = e
                              .toString()
                              .replaceAll(RegExp(r'Exception:\s*'), '')
                              .trim();
                          if (mounted) {
                            AppToast.show(
                              context,
                              message: msg,
                              type: ToastType.error,
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isGoogleLoading = false);
                        }
                      },
                      onAppleSignIn: () {},
                    ),

                    SizedBox(height: 4.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        GestureDetector(
                          onTap: _navigateToLogin,
                          child: Text(
                            'Login',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
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
            if (state.isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
