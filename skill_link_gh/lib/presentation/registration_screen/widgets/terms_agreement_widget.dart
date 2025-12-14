import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Terms and privacy agreement widget
class TermsAgreementWidget extends StatelessWidget {
  final bool isAgreed;
  final ValueChanged<bool?> onChanged;

  const TermsAgreementWidget({
    super.key,
    required this.isAgreed,
    required this.onChanged,
  });

  void _showTermsDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Terms of Service', style: theme.textTheme.titleLarge),
        content: SingleChildScrollView(
          child: Text(
            'By creating an account, you agree to our Terms of Service and Privacy Policy. '
            'These terms govern your use of SkillLink and outline your rights and responsibilities. '
            'Please read them carefully before proceeding.',
            style: theme.textTheme.bodyMedium,
          ),
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

  void _showPrivacyDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Privacy Policy', style: theme.textTheme.titleLarge),
        content: SingleChildScrollView(
          child: Text(
            'Your privacy is important to us. This policy explains how we collect, use, and protect '
            'your personal information. We are committed to maintaining the confidentiality and security '
            'of your data in accordance with applicable laws.',
            style: theme.textTheme.bodyMedium,
          ),
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: isAgreed,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              children: [
                const TextSpan(text: 'I agree to the '),
                TextSpan(
                  text: 'Terms of Service',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => _showTermsDialog(context),
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => _showPrivacyDialog(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
