import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Custom text field for login form with validation
class LoginFormField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String iconName;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool showError;
  final String? errorText;
  final VoidCallback? onChanged;
  final VoidCallback? onForgotPassword; // ✅ NEW

  const LoginFormField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.iconName,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.showError = false,
    this.errorText,
    this.onChanged,
    this.onForgotPassword,
  });

  @override
  State<LoginFormField> createState() => _LoginFormFieldState();
}

class _LoginFormFieldState extends State<LoginFormField> {
  bool _obscureText = true;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 1.h),

        Focus(
          onFocusChange: (hasFocus) {
            setState(() => _isFocused = hasFocus);
          },
          child: TextFormField(
            controller: widget.controller,
            obscureText: widget.isPassword && _obscureText,
            keyboardType: widget.keyboardType,
            textInputAction:
                widget.isPassword ? TextInputAction.done : TextInputAction.next,
            style: theme.textTheme.bodyLarge,
            onChanged: (_) => widget.onChanged?.call(),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              prefixIcon: Padding(
                padding: EdgeInsets.all(3.w),
                child: CustomIconWidget(
                  iconName: widget.iconName,
                  size: 20,
                  color: _isFocused
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: CustomIconWidget(
                        iconName:
                            _obscureText ? 'visibility_off' : 'visibility',
                        size: 20,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      onPressed: () =>
                          setState(() => _obscureText = !_obscureText),
                    )
                  : null,
              filled: true,
              fillColor: theme.colorScheme.surface,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
              border: _border(theme),
              enabledBorder: _border(theme),
              focusedBorder: _focusedBorder(theme),
              errorBorder: _errorBorder(theme),
              focusedErrorBorder: _focusedErrorBorder(theme),
            ),
          ),
        ),

        /// 🔹 Forgot password (ONLY for password field)
        if (widget.isPassword && widget.onForgotPassword != null) ...[
          SizedBox(height: 0.8.h),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: widget.onForgotPassword,
              child: const Text('Forgot password?'),
            ),
          ),
        ],

        if (widget.showError && widget.errorText != null) ...[
          SizedBox(height: 0.5.h),
          Row(
            children: [
              CustomIconWidget(
                iconName: 'error_outline',
                size: 14,
                color: theme.colorScheme.error,
              ),
              SizedBox(width: 1.w),
              Expanded(
                child: Text(
                  widget.errorText!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  OutlineInputBorder _border(ThemeData theme) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: widget.showError
              ? theme.colorScheme.error
              : theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      );

  OutlineInputBorder _focusedBorder(ThemeData theme) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: widget.showError
              ? theme.colorScheme.error
              : theme.colorScheme.primary,
          width: 2,
        ),
      );

  OutlineInputBorder _errorBorder(ThemeData theme) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.error),
      );

  OutlineInputBorder _focusedErrorBorder(ThemeData theme) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: theme.colorScheme.error, width: 2),
      );
}
