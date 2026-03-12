import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';
import 'package:skill_link_gh/widgets/custom_app_toast.dart';
import 'package:skill_link_gh/widgets/custom_text_form_field.dart';

import '../../widgets/custom_app_bar.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Controllers
  final _idNumberController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _businessRegNumberController = TextEditingController();

  // State
  File? _idFrontImage;
  File? _idBackImage;
  File? _businessCertImage;
  File? _skillCertImage;
  String _selectedIdType = 'Ghana Card';
  bool _isLoading = false;

  final List<String> _idTypes = [
    'Ghana Card',
    'Voter ID',
    'Passport',
    'Driver\'s License',
  ];

  @override
  void dispose() {
    _idNumberController.dispose();
    _businessNameController.dispose();
    _businessRegNumberController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String imageType) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          switch (imageType) {
            case 'id_front':
              _idFrontImage = File(pickedFile.path);
              break;
            case 'id_back':
              _idBackImage = File(pickedFile.path);
              break;
            case 'business_cert':
              _businessCertImage = File(pickedFile.path);
              break;
            case 'skill_cert':
              _skillCertImage = File(pickedFile.path);
              break;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          message: 'Failed to pick image: $e',
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.validate()) return;

    if (_idFrontImage == null || _idBackImage == null) {
      AppToast.show(
        context,
        message: 'Please upload both front and back of your ID',
        type: ToastType.error,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // TODO: Implement verification submission
      // final verificationData = {
      //   'idType': _selectedIdType,
      //   'idNumber': _idNumberController.text.trim(),
      //   'businessName': _businessNameController.text.trim(),
      //   'businessRegNumber': _businessRegNumberController.text.trim(),
      // };

      // await ref.read(verificationProvider.notifier).submitVerification(
      //   verificationData: verificationData,
      //   idFrontImage: _idFrontImage!,
      //   idBackImage: _idBackImage!,
      //   businessCertImage: _businessCertImage,
      //   skillCertImage: _skillCertImage,
      // );

      if (mounted) {
        AppToast.show(
          context,
          message:
              'Verification submitted successfully! We\'ll review it within 24-48 hours.',
          type: ToastType.success,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          message: 'Failed to submit verification: $e',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        variant: AppBarVariant.standard,
        title: 'Account Verification',
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(theme),
              SizedBox(height: 3.h),
              _buildIdentityVerificationSection(theme),
              SizedBox(height: 3.h),
              _buildBusinessVerificationSection(theme),
              SizedBox(height: 3.h),
              _buildSkillVerificationSection(theme),
              SizedBox(height: 3.h),
              _buildSubmitButton(theme),
              SizedBox(height: 5.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.verified_user, size: 64, color: theme.colorScheme.primary),
          SizedBox(height: 2.h),
          Text(
            'Get Verified',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Increase your credibility and get more bookings by verifying your identity and skills.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityVerificationSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.person, color: theme.colorScheme.primary),
            SizedBox(width: 2.w),
            Text(
              'Identity Verification',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Required',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),

        // ID Type Dropdown
        DropdownButtonFormField<String>(
          value: _selectedIdType,
          decoration: const InputDecoration(
            labelText: 'ID Type',
            border: OutlineInputBorder(),
          ),
          items: _idTypes
              .map((type) => DropdownMenuItem(value: type, child: Text(type)))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedIdType = value);
            }
          },
        ),

        SizedBox(height: 2.h),

        // ID Number
        CustomTextFormField(
          controller: _idNumberController,
          hintText: 'ID Number',
          validator: (value) =>
              value?.isEmpty == true ? 'Please enter your ID number' : null,
        ),

        SizedBox(height: 2.h),

        // ID Images
        Row(
          children: [
            Expanded(
              child: _buildImageUploadCard(
                theme,
                title: 'ID Front',
                image: _idFrontImage,
                onTap: () => _pickImage('id_front'),
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: _buildImageUploadCard(
                theme,
                title: 'ID Back',
                image: _idBackImage,
                onTap: () => _pickImage('id_back'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBusinessVerificationSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.business, color: theme.colorScheme.primary),
            SizedBox(width: 2.w),
            Text(
              'Business Verification',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Optional',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        Text(
          'For registered businesses only',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 2.h),

        CustomTextFormField(
          controller: _businessNameController,
          hintText: 'Business Name',
        ),
        SizedBox(height: 2.h),

        CustomTextFormField(
          controller: _businessRegNumberController,
          hintText: 'Business Registration Number',
        ),
        SizedBox(height: 2.h),

        _buildImageUploadCard(
          theme,
          title: 'Business Certificate',
          image: _businessCertImage,
          onTap: () => _pickImage('business_cert'),
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildSkillVerificationSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.school, color: theme.colorScheme.primary),
            SizedBox(width: 2.w),
            Text(
              'Skill Verification',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Optional',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        Text(
          'Upload certificates or qualifications related to your skills',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 2.h),

        _buildImageUploadCard(
          theme,
          title: 'Skill Certificate',
          image: _skillCertImage,
          onTap: () => _pickImage('skill_cert'),
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildImageUploadCard(
    ThemeData theme, {
    required String title,
    required File? image,
    required VoidCallback onTap,
    bool isFullWidth = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: isFullWidth ? double.infinity : null,
        height: 15.h,
        decoration: BoxDecoration(
          border: Border.all(
            color: image != null
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: image != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      image,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.edit,
                        size: 16,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: 32,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Tap to upload',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitVerification,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 2.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                'Submit for Verification',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
