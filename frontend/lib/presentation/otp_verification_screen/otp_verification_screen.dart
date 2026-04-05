import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:skill_link_gh/presentation/otp_verification_screen/widgets/email_header_widget.dart';
import 'package:skill_link_gh/routes/app_routes.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/help_section_widget.dart';
import './widgets/otp_input_widget.dart';
import './widgets/resend_timer_widget.dart';

/// OTP Verification Screen for email validation
class OtpVerificationScreen extends StatefulWidget {
  final String email;
  const OtpVerificationScreen({super.key, required this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isVerified = false;

  final functions = FirebaseFunctions.instance;

  @override
  void initState() {
    super.initState();
    // Send OTP automatically when the page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendInitialOtp();
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  // Send initial OTP automatically
  Future<void> _sendInitialOtp() async {
    setState(() => _isLoading = true);

    try {
      final result = await functions
          .httpsCallable('resendVerificationCode')
          .call({'email': widget.email});

      if (result.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Verification code sent successfully to ${widget.email}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          _hasError = true;
          _errorMessage =
              result.data['message'] ?? 'Failed to send verification code';
        });
      }
    } catch (err) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to send OTP. Please try again.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Verify OTP via Firebase Function
  Future<void> _handleOtpCompleted(String otp) async {
    if (_isLoading || otp.length != 6) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final result = await functions
          .httpsCallable('verifyEmailCode')
          .call({'code': otp.trim(), 'email': widget.email});

      if (result.data['success'] == true) {
        setState(() => _isVerified = true);
        HapticFeedback.heavyImpact();

        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!mounted) return;
           Navigator.pushNamedAndRemoveUntil(
          context,
          '/posts-homepage',
          (route) => false,
        );
      
        });
      } else {
        _showFriendlyError(result.data['message']);
      }
    } on FirebaseFunctionsException catch (err) {
      _showFriendlyError(err.message);
    } catch (err) {
      setState(() {
        _hasError = true;
        _errorMessage =
            'An unexpected error occurred. Please try again later.';
      });
      HapticFeedback.vibrate();
      _clearErrorAfterDelay();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showFriendlyError(String? message) {
    String friendlyMessage = message ?? 'Verification failed';

    if (friendlyMessage.contains('No verification code found')) {
      friendlyMessage =
          'No OTP found. Please request a new code using "Resend".';
    } else if (friendlyMessage.contains('Incorrect verification code')) {
      friendlyMessage = 'The code entered is incorrect. Please try again.';
    } else if (friendlyMessage.contains('expired')) {
      friendlyMessage =
          'This code has expired. Please request a new verification code.';
    }

    setState(() {
      _hasError = true;
      _errorMessage = friendlyMessage;
    });

    HapticFeedback.vibrate();
    _clearErrorAfterDelay();
  }

  // Resend OTP via Firebase Function
  Future<void> _handleResendCode() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final result = await functions
          .httpsCallable('resendVerificationCode')
          .call({'email': widget.email});

      if (result.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Verification code sent successfully to ${widget.email}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );

        _otpController.clear();
      } else {
        _showFriendlyError(result.data['message']);
      }
    } on FirebaseFunctionsException catch (err) {
      _showFriendlyError(err.message);
    } catch (err) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to resend OTP. Please try again.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleEditEmail() {
    Navigator.pop(context);
  }

  void _handleContactSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: const Text(
          'For assistance, please contact our support team:\n\nEmail: support@skilllink.com\n\nOur team is available 24/7.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _clearErrorAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _hasError = false;
        _errorMessage = '';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            size: 24,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'SkillLink GH Email Verification',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),

              // Header with email
              EmailHeaderWidget(
                email: widget.email,
                onEdit: _handleEditEmail,
              ),

              const SizedBox(height: 48),

              // OTP Input
              OtpInputWidget(
                controller: _otpController,
                focusNode: _otpFocusNode,
                onCompleted: _handleOtpCompleted,
                hasError: _hasError,
              ).animate(target: _hasError ? 1 : 0).shake(
                    duration: const Duration(milliseconds: 500),
                    hz: 4,
                  ),

              if (_hasError && _errorMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'error_outline',
                      size: 18,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 32),

              // Verify Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _otpController.text.length == 6 && !_isLoading
                      ? () => _handleOtpCompleted(_otpController.text)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    disabledBackgroundColor:
                        theme.colorScheme.onSurface.withOpacity(0.12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : _isVerified
                          ? CustomIconWidget(
                              iconName: 'check_circle',
                              size: 28,
                              color: theme.colorScheme.onPrimary,
                            ).animate().scale(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.elasticOut,
                              )
                          : Text(
                              'Verify',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                ),
              ),

              const SizedBox(height: 24),

              // Resend Timer
              ResendTimerWidget(
                onResend: _handleResendCode,
                initialSeconds: 60,
              ),

              const SizedBox(height: 32),

              // Help Section
              HelpSectionWidget(
                onContactSupport: _handleContactSupport,
              ),

              const SizedBox(height: 24),

              // Info box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'info_outline',
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'The code will be sent to your email address',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
