import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Registration form widget containing all input fields
class RegistrationFormWidget extends StatefulWidget {
  final bool isArtisan;
  final GlobalKey<FormState> formKey;
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController? businessNameController;
  final TextEditingController? descriptionController;
  final String? selectedCategory;
  final ValueChanged<String?>? onCategoryChanged;

  const RegistrationFormWidget({
    super.key,
    required this.isArtisan,
    required this.formKey,
    required this.fullNameController,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    required this.confirmPasswordController,
    this.businessNameController,
    this.descriptionController,
    this.selectedCategory,
    this.onCategoryChanged,
  });

  @override
  State<RegistrationFormWidget> createState() => _RegistrationFormWidgetState();
}

class _RegistrationFormWidgetState extends State<RegistrationFormWidget> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  double _passwordStrength = 0.0;
  String _passwordStrengthText = '';

  final List<String> _serviceCategories = [
    'Plumbing',
    'Electrical',
    'Carpentry',
    'Painting',
    'Masonry',
    'Welding',
    'Tailoring',
    'Hairdressing',
    'Catering',
    'Photography',
    'Auto Repair',
    'Cleaning Services',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            controller: widget.fullNameController,
            label: 'Full Name',
            hint: 'Enter your full name',
            prefixIcon: 'person',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your full name';
              }
              if (value.length < 3) {
                return 'Name must be at least 3 characters';
              }
              return null;
            },
          ),
          SizedBox(height: 2.h),
          _buildTextField(
            controller: widget.emailController,
            label: 'Email Address',
            hint: 'Enter your email',
            prefixIcon: 'email',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!emailRegex.hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          SizedBox(height: 2.h),
          _buildPhoneField(),
          SizedBox(height: 2.h),
          _buildPasswordField(),
          if (_passwordStrength > 0) ...[
            SizedBox(height: 1.h),
            _buildPasswordStrengthIndicator(theme),
          ],
          SizedBox(height: 2.h),
          _buildTextField(
            controller: widget.confirmPasswordController,
            label: 'Confirm Password',
            hint: 'Re-enter your password',
            prefixIcon: 'lock',
            obscureText: _obscureConfirmPassword,
            suffixIcon: IconButton(
              icon: CustomIconWidget(
                iconName:
                    _obscureConfirmPassword ? 'visibility' : 'visibility_off',
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != widget.passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          if (widget.isArtisan) ...[
            SizedBox(height: 3.h),
            Text(
              'Business Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            _buildTextField(
              controller: widget.businessNameController!,
              label: 'Business Name',
              hint: 'Enter your business name',
              prefixIcon: 'business',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your business name';
                }
                return null;
              },
            ),
            SizedBox(height: 2.h),
            _buildCategoryPicker(theme),
            SizedBox(height: 2.h),
            _buildTextField(
              controller: widget.descriptionController!,
              label: 'Brief Description',
              hint: 'Tell us about your services',
              prefixIcon: 'description',
              maxLines: 4,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please provide a brief description';
                }
                if (value.length < 20) {
                  return 'Description must be at least 20 characters';
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String prefixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Padding(
          padding: EdgeInsets.all(3.w),
          child: CustomIconWidget(
            iconName: prefixIcon,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        suffixIcon: suffixIcon,
      ),
      validator: validator,
    );
  }

  Widget _buildPhoneField() {
    final theme = Theme.of(context);

    return TextFormField(
      controller: widget.phoneController,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      decoration: InputDecoration(
        labelText: 'Phone Number',
        hintText: 'Enter your phone number',
        prefixIcon: Padding(
          padding: EdgeInsets.all(3.w),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomIconWidget(
                iconName: 'phone',
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: 2.w),
              Text(
                '+233',
                style: theme.textTheme.bodyMedium,
              ),
              SizedBox(width: 1.w),
              Container(
                width: 1,
                height: 20,
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your phone number';
        }
        if (value.length != 10) {
          return 'Phone number must be 10 digits';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    final theme = Theme.of(context);

    return TextFormField(
      controller: widget.passwordController,
      obscureText: _obscurePassword,
      onChanged: (value) {
        setState(() {
          _calculatePasswordStrength(value);
        });
      },
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Create a strong password',
        prefixIcon: Padding(
          padding: EdgeInsets.all(3.w),
          child: CustomIconWidget(
            iconName: 'lock',
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        suffixIcon: IconButton(
          icon: CustomIconWidget(
            iconName: _obscurePassword ? 'visibility' : 'visibility_off',
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a password';
        }
        if (value.length < 8) {
          return 'Password must be at least 8 characters';
        }
        if (!RegExp(r'[A-Z]').hasMatch(value)) {
          return 'Password must contain at least one uppercase letter';
        }
        if (!RegExp(r'[a-z]').hasMatch(value)) {
          return 'Password must contain at least one lowercase letter';
        }
        if (!RegExp(r'[0-9]').hasMatch(value)) {
          return 'Password must contain at least one number';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordStrengthIndicator(ThemeData theme) {
    Color strengthColor;
    if (_passwordStrength < 0.3) {
      strengthColor = theme.colorScheme.error;
    } else if (_passwordStrength < 0.7) {
      strengthColor = AppTheme.warningLight;
    } else {
      strengthColor = AppTheme.successLight;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _passwordStrength,
            backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
            minHeight: 4,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          _passwordStrengthText,
          style: theme.textTheme.bodySmall?.copyWith(
            color: strengthColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryPicker(ThemeData theme) {
    return DropdownButtonFormField<String>(
      value: widget.selectedCategory,
      decoration: InputDecoration(
        labelText: 'Service Category',
        hintText: 'Select your service category',
        prefixIcon: Padding(
          padding: EdgeInsets.all(3.w),
          child: CustomIconWidget(
            iconName: 'category',
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      items: _serviceCategories.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Text(category),
        );
      }).toList(),
      onChanged: widget.onCategoryChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a service category';
        }
        return null;
      },
    );
  }

  void _calculatePasswordStrength(String password) {
    double strength = 0.0;
    String strengthText = '';

    if (password.isEmpty) {
      strength = 0.0;
      strengthText = '';
    } else if (password.length < 8) {
      strength = 0.2;
      strengthText = 'Weak';
    } else {
      strength = 0.4;
      if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.15;
      if (RegExp(r'[a-z]').hasMatch(password)) strength += 0.15;
      if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.15;
      if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password))
        strength += 0.15;

      if (strength < 0.5) {
        strengthText = 'Weak';
      } else if (strength < 0.8) {
        strengthText = 'Medium';
      } else {
        strengthText = 'Strong';
      }
    }

    _passwordStrength = strength;
    _passwordStrengthText = strengthText;
  }
}
