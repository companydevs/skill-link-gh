import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Registration form widget containing all input fields
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
  String _selectedCountryCode = '+1';
  int _businessDescriptionLength = 0;

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
    if (password.isEmpty) {
      setState(() {
        _passwordStrength = '';
        _passwordStrengthColor = Colors.grey;
      });
      return;
    }

    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    setState(() {
      if (strength <= 1) {
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

  void _showCountryCodePicker() {
    final theme = Theme.of(context);
    final countryCodes = [
      {'code': '+1', 'country': 'United States'},
      {'code': '+44', 'country': 'United Kingdom'},
      {'code': '+91', 'country': 'India'},
      {'code': '+86', 'country': 'China'},
      {'code': '+81', 'country': 'Japan'},
      {'code': '+49', 'country': 'Germany'},
      {'code': '+33', 'country': 'France'},
      {'code': '+39', 'country': 'Italy'},
      {'code': '+34', 'country': 'Spain'},
      {'code': '+61', 'country': 'Australia'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => Container(
            padding: EdgeInsets.symmetric(vertical: 2.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  child: Text(
                    'Select Country Code',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                Divider(color: theme.dividerColor),
                Expanded(
                  child: ListView.builder(
                    itemCount: countryCodes.length,
                    itemBuilder: (context, index) {
                      final item = countryCodes[index];
                      return ListTile(
                        leading: Text(
                          item['code']!,
                          style: theme.textTheme.titleMedium,
                        ),
                        title: Text(
                          item['country']!,
                          style: theme.textTheme.bodyLarge,
                        ),
                        onTap: () {
                          setState(() => _selectedCountryCode = item['code']!);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  String? _validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Name can only contain letters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    if (!RegExp(r'^\d{10}$').hasMatch(value.replaceAll(RegExp(r'[\s-]'), ''))) {
      return 'Enter a valid 10-digit phone number';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain an uppercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain a number';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != widget.passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? _validateBusinessName(String? value) {
    if (!widget.isArtisan) return null; // Skip validation for clients

    if (value == null || value.trim().isEmpty) {
      return 'Business name is required';
    }
    if (value.trim().length < 2) {
      return 'Business name must be at least 2 characters';
    }
    return null;
  }

  String? _validateBusinessDescription(String? value) {
    if (!widget.isArtisan) return null; // Skip validation for clients

    if (value == null || value.trim().isEmpty) {
      return 'Business description is required';
    }
    if (value.trim().length < 20) {
      return 'Description must be at least 20 characters';
    }
    if (value.length > 500) {
      return 'Description cannot exceed 500 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personal Information Section
          Text(
            'Personal Information',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 2.h),

          // Full Name Field
          TextFormField(
            controller: widget.fullNameController,
            focusNode: widget.fullNameFocus,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Full Name',
              hintText: 'Enter your full name',
              prefixIcon: Padding(
                padding: EdgeInsets.all(3.w),
                child: CustomIconWidget(
                  iconName: 'person_outline',
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 24,
                ),
              ),
            ),
            validator: _validateFullName,
            onFieldSubmitted: (_) => widget.emailFocus.requestFocus(),
          ),
          SizedBox(height: 2.h),

          // Email Field
          TextFormField(
            controller: widget.emailController,
            focusNode: widget.emailFocus,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Email Address',
              hintText: 'Enter your email',
              prefixIcon: Padding(
                padding: EdgeInsets.all(3.w),
                child: CustomIconWidget(
                  iconName: 'email_outlined',
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 24,
                ),
              ),
            ),
            validator: _validateEmail,
            onFieldSubmitted: (_) => widget.phoneFocus.requestFocus(),
          ),
          SizedBox(height: 2.h),

          // Phone Number Field
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: _showCountryCodePicker,
                child: Container(
                  height: 6.h,
                  padding: EdgeInsets.symmetric(horizontal: 3.w),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.dividerColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _selectedCountryCode,
                        style: theme.textTheme.bodyLarge,
                      ),
                      SizedBox(width: 1.w),
                      CustomIconWidget(
                        iconName: 'arrow_drop_down',
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: TextFormField(
                  controller: widget.phoneController,
                  focusNode: widget.phoneFocus,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'Enter phone number',
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(3.w),
                      child: CustomIconWidget(
                        iconName: 'phone_outlined',
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                    ),
                  ),
                  validator: _validatePhone,
                  onFieldSubmitted: (_) => widget.passwordFocus.requestFocus(),
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),

          // Security Section
          Text(
            'Security',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 2.h),

          // Password Field
          TextFormField(
            controller: widget.passwordController,
            focusNode: widget.passwordFocus,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter password',
              prefixIcon: Padding(
                padding: EdgeInsets.all(3.w),
                child: CustomIconWidget(
                  iconName: 'lock_outline',
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 24,
                ),
              ),
              suffixIcon: IconButton(
                icon: CustomIconWidget(
                  iconName:
                      _obscurePassword
                          ? 'visibility_outlined'
                          : 'visibility_off_outlined',
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 24,
                ),
                onPressed:
                    () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: _validatePassword,
            onFieldSubmitted: (_) => widget.confirmPasswordFocus.requestFocus(),
          ),
          _passwordStrength.isNotEmpty
              ? Column(
                children: [
                  SizedBox(height: 1.h),
                  Row(
                    children: [
                      Text('Strength: ', style: theme.textTheme.bodySmall),
                      Text(
                        _passwordStrength,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _passwordStrengthColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              )
              : const SizedBox.shrink(),
          SizedBox(height: 2.h),

          // Confirm Password Field
          TextFormField(
            controller: widget.confirmPasswordController,
            focusNode: widget.confirmPasswordFocus,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              hintText: 'Re-enter password',
              prefixIcon: Padding(
                padding: EdgeInsets.all(3.w),
                child: CustomIconWidget(
                  iconName: 'lock_outline',
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 24,
                ),
              ),
              suffixIcon: IconButton(
                icon: CustomIconWidget(
                  iconName:
                      _obscureConfirmPassword
                          ? 'visibility_outlined'
                          : 'visibility_off_outlined',
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 24,
                ),
                onPressed:
                    () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
              ),
            ),
            validator: _validateConfirmPassword,
            onFieldSubmitted: (_) => widget.businessNameFocus.requestFocus(),
          ),
          SizedBox(height: 3.h),

          // Business Details Section - Only for artisans
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

            // Business Name Field
            TextFormField(
              controller: widget.businessNameController,
              focusNode: widget.businessNameFocus,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Business Name',
                hintText: 'Enter your business name',
                prefixIcon: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: CustomIconWidget(
                    iconName: 'business_outlined',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
              ),
              validator: _validateBusinessName,
              onFieldSubmitted:
                  (_) => widget.businessDescriptionFocus.requestFocus(),
            ),
            SizedBox(height: 2.h),

            // Business Description Field
            TextFormField(
              controller: widget.businessDescriptionController,
              focusNode: widget.businessDescriptionFocus,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.done,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: 'Business Description',
                hintText: 'Describe your business and services',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(top: 3.w, left: 3.w, right: 3.w),
                  child: CustomIconWidget(
                    iconName: 'description_outlined',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
                alignLabelWithHint: true,
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
