import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

/// OTP input widget with six-digit code entry
class OtpInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String) onCompleted;
  final bool hasError;

  const OtpInputWidget({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onCompleted,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );

    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.error,
          width: 2.0,
        ),
      ),
    );

    return Pinput(
      controller: controller,
      focusNode: focusNode,
      length: 6,
      defaultPinTheme: defaultPinTheme,
      focusedPinTheme: focusedPinTheme,
      errorPinTheme: hasError ? errorPinTheme : defaultPinTheme,
      onCompleted: onCompleted,
      keyboardType: TextInputType.number,
      autofocus: true,
      hapticFeedbackType: HapticFeedbackType.lightImpact,
      cursor: Container(
        width: 2,
        height: 24,
        color: theme.colorScheme.primary,
      ),
      separatorBuilder: (index) => const SizedBox(width: 12),
    );
  }
}
