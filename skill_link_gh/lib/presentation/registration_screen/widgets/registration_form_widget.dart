import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:sizer/sizer.dart';

class RegistrationFormWidget extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController businessNameController;
  final TextEditingController businessDescriptionController;
  final FocusNode fullNameFocus;
  final FocusNode emailFocus;
  final FocusNode phoneFocus;
  final FocusNode passwordFocus;
  final FocusNode confirmPasswordFocus;
  final FocusNode businessNameFocus;
  final FocusNode businessDescriptionFocus;
  final bool isArtisan;

  const RegistrationFormWidget({
    super.key,
    required this.formKey,
    required this.fullNameController,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.businessNameController,
    required this.businessDescriptionController,
    required this.fullNameFocus,
    required this.emailFocus,
    required this.phoneFocus,
    required this.passwordFocus,
    required this.confirmPasswordFocus,
    required this.businessNameFocus,
    required this.businessDescriptionFocus,
    this.isArtisan = true,
  });

  @override
  State<RegistrationFormWidget> createState() => _RegistrationFormWidgetState();
}

class _RegistrationFormWidgetState extends State<RegistrationFormWidget> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _passwordStrength = '';
  Color _passwordStrengthColor = Colors.grey;
  int _businessDescriptionLength = 0;
  String _fullPhoneNumber = '';

  @override
  void initState() {
    super.initState();
    widget.passwordController.addListener(_updatePasswordStrength);
    widget.businessDescriptionController.addListener(_updateDescriptionLength);
  }

  @override
  void dispose() {
    widget.passwordController.removeListener(_updatePasswordStrength);
    widget.businessDescriptionController.removeListener(
      _updateDescriptionLength,
    );
    super.dispose();
  }

  void _updatePasswordStrength() {
    final password = widget.passwordController.text;
    int strength = 0;

    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    setState(() {
      if (password.isEmpty) {
        _passwordStrength = '';
        _passwordStrengthColor = Colors.grey;
      } else if (strength <= 1) {
        _passwordStrength = 'Weak';
        _passwordStrengthColor = Colors.red;
      } else if (strength == 2) {
        _passwordStrength = 'Fair';
        _passwordStrengthColor = Colors.orange;
      } else if (strength == 3) {
        _passwordStrength = 'Good';
        _passwordStrengthColor = Colors.blue;
      } else {
        _passwordStrength = 'Strong';
        _passwordStrengthColor = Colors.green;
      }
    });
  }

  void _updateDescriptionLength() {
    setState(() {
      _businessDescriptionLength =
          widget.businessDescriptionController.text.length;
    });
  }

  // ================= VALIDATORS =================

  String? _validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Full name is required';
    if (value.trim().length < 2) return 'Name too short';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password required';
    if (value.length < 8) return 'Minimum 8 characters';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Confirm password';
    if (value != widget.passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? _validateBusinessName(String? value) {
    if (!widget.isArtisan) return null;
    if (value == null || value.isEmpty) return 'Business name required';
    return null;
  }

  String? _validateBusinessDescription(String? value) {
    if (!widget.isArtisan) return null;
    if (value == null || value.length < 20) {
      return 'Minimum 20 characters';
    }
    return null;
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 2.h),

          /// Full Name
          TextFormField(
            controller: widget.fullNameController,
            focusNode: widget.fullNameFocus,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Full Name'),
            validator: _validateFullName,
            onFieldSubmitted: (_) => widget.emailFocus.requestFocus(),
          ),
          SizedBox(height: 2.h),

          /// Email
          TextFormField(
            controller: widget.emailController,
            focusNode: widget.emailFocus,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Email Address'),
            validator: _validateEmail,
            onFieldSubmitted: (_) => widget.phoneFocus.requestFocus(),
          ),
          SizedBox(height: 2.h),

          /// 🌍 PHONE FIELD (ALL COUNTRIES)
          ///
          ///
          IntlPhoneField(
            controller: widget.phoneController,
            focusNode: widget.phoneFocus,
            initialCountryCode: 'GH',
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(),
            ),
            onChanged: (phone) {
              // phone.completeNumber -> +233xxxxxxxx
              _fullPhoneNumber = phone.completeNumber; // store it
            },
            validator: (phone) {
              if (phone == null || phone.number.isEmpty) {
                return 'Phone number required';
              }
              return null;
            },
          ),
          SizedBox(height: 3.h),

          Text(
            'Security',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 2.h),

          /// Password
          TextFormField(
            controller: widget.passwordController,
            focusNode: widget.passwordFocus,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Password',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: _validatePassword,
            onFieldSubmitted: (_) => widget.confirmPasswordFocus.requestFocus(),
          ),

          if (_passwordStrength.isNotEmpty) ...[
            SizedBox(height: 1.h),
            Text(
              'Strength: $_passwordStrength',
              style: TextStyle(color: _passwordStrengthColor),
            ),
          ],

          SizedBox(height: 2.h),

          /// Confirm Password
          TextFormField(
            controller: widget.confirmPasswordController,
            focusNode: widget.confirmPasswordFocus,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
              ),
            ),
            validator: _validateConfirmPassword,
          ),

          if (widget.isArtisan) ...[
            SizedBox(height: 3.h),
            Text(
              'Business Details',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(height: 2.h),

            TextFormField(
              controller: widget.businessNameController,
              focusNode: widget.businessNameFocus,
              decoration: const InputDecoration(labelText: 'Business Name'),
              validator: _validateBusinessName,
            ),
            SizedBox(height: 2.h),

            TextFormField(
              controller: widget.businessDescriptionController,
              focusNode: widget.businessDescriptionFocus,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: 'Business Description',
                counterText: '$_businessDescriptionLength/500',
              ),
              validator: _validateBusinessDescription,
            ),
          ],
        ],
      ),
    );
  }
}
