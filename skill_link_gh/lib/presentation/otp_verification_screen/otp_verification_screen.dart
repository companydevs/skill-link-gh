import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/help_section_widget.dart';
import './widgets/otp_input_widget.dart';
import './widgets/phone_header_widget.dart';
import './widgets/resend_timer_widget.dart';

/// OTP Verification Screen for phone number validation
class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

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

  // Mock phone number - in real app, this would come from previous screen
  final String _phoneNumber = '+1 (555) 123-4567';

  // Mock correct OTP for testing
  final String _correctOtp = '123456';

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _handleOtpCompleted(String otp) {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    // Simulate API verification with delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;

      if (otp == _correctOtp) {
        // Success - show checkmark animation
        setState(() {
          _isLoading = false;
          _isVerified = true;
        });

        HapticFeedback.heavyImpact();

        // Navigate to next screen after animation
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/artisan-profile-screen');
        });
      } else {
        // Error - show shake animation and vibration
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Invalid verification code. Please try again.';
        });

        HapticFeedback.vibrate();

        // Clear error after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (!mounted) return;
          setState(() {
            _hasError = false;
            _errorMessage = '';
          });
        });
      }
    });
  }

  void _handleResendCode() {
    // Simulate resending code
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Verification code sent successfully'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );

    // Clear current input
    _otpController.clear();
    setState(() {
      _hasError = false;
      _errorMessage = '';
    });
  }

  void _handleEditPhone() {
    Navigator.pop(context);
  }

  void _handleContactSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: const Text(
          'For assistance, please contact our support team:\n\nEmail: support@skilllink.com\nPhone: +1 (800) 555-0123\n\nOur team is available 24/7 to help you.',
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
          'Verify Phone',
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

              // Header with phone number
              PhoneHeaderWidget(
                phoneNumber: _phoneNumber,
                onEdit: _handleEditPhone,
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

              // Error message
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
                        theme.colorScheme.onSurface.withValues(alpha: 0.12),
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

              // Auto-fill info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.05),
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
                        'The code will be automatically detected from your SMS',
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
