import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';
import 'package:skill_link_gh/widgets/custom_app_toast.dart';
import 'package:skill_link_gh/widgets/custom_text_form_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../provider/verification_provider.dart';
import '../../widgets/custom_app_bar.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  final _idNumberController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _businessRegNumberController = TextEditingController();

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
    "Driver's License",
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
      final success = await ref
          .read(verificationNotifierProvider.notifier)
          .submitVerification(
            idType: _selectedIdType,
            idNumber: _idNumberController.text.trim(),
            idFrontImage: _idFrontImage!,
            idBackImage: _idBackImage!,
            businessCertImage: _businessCertImage,
            skillCertImage: _skillCertImage,
            businessName: _businessNameController.text.trim(),
            businessRegNumber: _businessRegNumberController.text.trim(),
          );
      if (mounted) {
        if (success) {
          AppToast.show(
            context,
            message: "Submitted! We'll review within 24–48 hours.",
            type: ToastType.success,
          );
          Navigator.pop(context);
        } else {
          final error = ref.read(verificationNotifierProvider).error;
          AppToast.show(
            context,
            message: 'Failed to submit: ${error ?? 'Unknown error'}',
            type: ToastType.error,
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int get _completedSteps {
    int count = 0;
    if (_idFrontImage != null &&
        _idBackImage != null &&
        _idNumberController.text.isNotEmpty)
      count++;
    if (_businessCertImage != null) count++;
    if (_skillCertImage != null) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verificationState = ref.watch(verificationNotifierProvider);

    // If already submitted, show status screen
    if (verificationState.isSubmitted && verificationState.status != null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CustomAppBar(
          variant: AppBarVariant.standard,
          title: 'Verification Status',
        ),
        body: _VerificationStatusView(
          status: verificationState.status!,
          theme: theme,
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        variant: AppBarVariant.standard,
        title: 'Get Verified',
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroBanner(theme: theme),
              SizedBox(height: 2.h),
              _ProgressRow(completed: _completedSteps, total: 3, theme: theme),
              SizedBox(height: 3.h),
              _SectionCard(
                theme: theme,
                icon: Icons.badge_outlined,
                title: 'Identity Verification',
                badge: _RequiredBadge(theme: theme),
                child: _IdentitySection(
                  theme: theme,
                  idTypes: _idTypes,
                  selectedIdType: _selectedIdType,
                  idNumberController: _idNumberController,
                  idFrontImage: _idFrontImage,
                  idBackImage: _idBackImage,
                  onIdTypeChanged: (v) => setState(() => _selectedIdType = v!),
                  onPickFront: () => _pickImage('id_front'),
                  onPickBack: () => _pickImage('id_back'),
                ),
              ),
              SizedBox(height: 2.h),
              _SectionCard(
                theme: theme,
                icon: Icons.storefront_outlined,
                title: 'Business Verification',
                badge: _OptionalBadge(theme: theme),
                subtitle: 'For registered businesses only',
                child: _BusinessSection(
                  theme: theme,
                  businessNameController: _businessNameController,
                  businessRegController: _businessRegNumberController,
                  certImage: _businessCertImage,
                  onPickCert: () => _pickImage('business_cert'),
                ),
              ),
              SizedBox(height: 2.h),
              _SectionCard(
                theme: theme,
                icon: Icons.workspace_premium_outlined,
                title: 'Skill Verification',
                badge: _OptionalBadge(theme: theme),
                subtitle: 'Upload certificates or qualifications',
                child: _SkillSection(
                  theme: theme,
                  certImage: _skillCertImage,
                  onPickCert: () => _pickImage('skill_cert'),
                ),
              ),
              SizedBox(height: 3.h),
              _SubmitButton(
                isLoading: _isLoading,
                onTap: _submitVerification,
                theme: theme,
              ),
              SizedBox(height: 4.h),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Verification status view ──────────────────────────────────────────────────
class _VerificationStatusView extends StatelessWidget {
  final String status;
  final ThemeData theme;
  const _VerificationStatusView({required this.status, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isPending = status == 'pending';
    final isApproved = status == 'approved';
    final isRejected = status == 'rejected';

    final color = isApproved
        ? Colors.green
        : isRejected
        ? theme.colorScheme.error
        : Colors.orange;

    final icon = isApproved
        ? Icons.verified_rounded
        : isRejected
        ? Icons.cancel_outlined
        : Icons.hourglass_top_rounded;

    final title = isApproved
        ? 'You\'re Verified! ✅'
        : isRejected
        ? 'Verification Rejected'
        : 'Under Review';

    final message = isApproved
        ? 'Your identity has been verified. You now have a verified badge on your profile.'
        : isRejected
        ? 'Your verification was rejected. Please resubmit with clearer documents.'
        : 'Your documents are being reviewed by our team. This usually takes 24–48 hours.';

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 50, color: color),
            ),
            SizedBox(height: 3.h),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (isRejected) ...[
              SizedBox(height: 3.h),
              ElevatedButton(
                onPressed: () {
                  // Allow resubmission by clearing Firestore doc
                  FirebaseFirestore.instance
                      .collection('verifications')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .delete();
                  Navigator.pushReplacementNamed(
                    context,
                    '/verification-screen',
                  );
                },
                child: const Text('Resubmit Documents'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Hero banner ───────────────────────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  final ThemeData theme;
  const _HeroBanner({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 3.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Get Verified',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Build trust, stand out, and unlock more bookings.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Progress row ──────────────────────────────────────────────────────────────
class _ProgressRow extends StatelessWidget {
  final int completed;
  final int total;
  final ThemeData theme;
  const _ProgressRow({
    required this.completed,
    required this.total,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: completed / total,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$completed / $total sections filled',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ── Section card wrapper ──────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget badge;
  final Widget child;

  const _SectionCard({
    required this.theme,
    required this.icon,
    required this.title,
    required this.badge,
    required this.child,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                badge,
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

// ── Badges ────────────────────────────────────────────────────────────────────
class _RequiredBadge extends StatelessWidget {
  final ThemeData theme;
  const _RequiredBadge({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Required',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _OptionalBadge extends StatelessWidget {
  final ThemeData theme;
  const _OptionalBadge({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Optional',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Identity section ──────────────────────────────────────────────────────────
class _IdentitySection extends StatelessWidget {
  final ThemeData theme;
  final List<String> idTypes;
  final String selectedIdType;
  final TextEditingController idNumberController;
  final File? idFrontImage;
  final File? idBackImage;
  final ValueChanged<String?> onIdTypeChanged;
  final VoidCallback onPickFront;
  final VoidCallback onPickBack;

  const _IdentitySection({
    required this.theme,
    required this.idTypes,
    required this.selectedIdType,
    required this.idNumberController,
    required this.idFrontImage,
    required this.idBackImage,
    required this.onIdTypeChanged,
    required this.onPickFront,
    required this.onPickBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: selectedIdType,
          decoration: InputDecoration(
            labelText: 'ID Type',
            prefixIcon: Icon(
              Icons.credit_card_outlined,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
          items: idTypes
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: onIdTypeChanged,
        ),
        const SizedBox(height: 12),
        CustomTextFormField(
          controller: idNumberController,
          hintText: 'ID Number',
          validator: (v) =>
              v?.isEmpty == true ? 'Please enter your ID number' : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _UploadTile(
                theme: theme,
                label: 'Front of ID',
                hint: 'Tap to upload',
                icon: Icons.flip_to_front_outlined,
                image: idFrontImage,
                onTap: onPickFront,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _UploadTile(
                theme: theme,
                label: 'Back of ID',
                hint: 'Tap to upload',
                icon: Icons.flip_to_back_outlined,
                image: idBackImage,
                onTap: onPickBack,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Business section ──────────────────────────────────────────────────────────
class _BusinessSection extends StatelessWidget {
  final ThemeData theme;
  final TextEditingController businessNameController;
  final TextEditingController businessRegController;
  final File? certImage;
  final VoidCallback onPickCert;

  const _BusinessSection({
    required this.theme,
    required this.businessNameController,
    required this.businessRegController,
    required this.certImage,
    required this.onPickCert,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomTextFormField(
          controller: businessNameController,
          hintText: 'Business Name',
        ),
        const SizedBox(height: 12),
        CustomTextFormField(
          controller: businessRegController,
          hintText: 'Registration Number',
        ),
        const SizedBox(height: 16),
        _UploadTile(
          theme: theme,
          label: 'Business Certificate',
          hint: 'Tap to upload document or photo',
          icon: Icons.description_outlined,
          image: certImage,
          onTap: onPickCert,
          fullWidth: true,
        ),
      ],
    );
  }
}

// ── Skill section ─────────────────────────────────────────────────────────────
class _SkillSection extends StatelessWidget {
  final ThemeData theme;
  final File? certImage;
  final VoidCallback onPickCert;

  const _SkillSection({
    required this.theme,
    required this.certImage,
    required this.onPickCert,
  });

  @override
  Widget build(BuildContext context) {
    return _UploadTile(
      theme: theme,
      label: 'Skill Certificate',
      hint: 'Tap to upload certificate or qualification',
      icon: Icons.school_outlined,
      image: certImage,
      onTap: onPickCert,
      fullWidth: true,
    );
  }
}

// ── Upload tile ───────────────────────────────────────────────────────────────
class _UploadTile extends StatelessWidget {
  final ThemeData theme;
  final String label;
  final String hint;
  final IconData icon;
  final File? image;
  final VoidCallback onTap;
  final bool fullWidth;

  const _UploadTile({
    required this.theme,
    required this.label,
    required this.hint,
    required this.icon,
    required this.image,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final uploaded = image != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: fullWidth ? double.infinity : null,
        height: 13.h,
        decoration: BoxDecoration(
          color: uploaded
              ? theme.colorScheme.primary.withValues(alpha: 0.05)
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: uploaded
                ? theme.colorScheme.primary.withValues(alpha: 0.5)
                : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: uploaded ? 1.5 : 1,
          ),
        ),
        child: uploaded
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Image.file(
                      image!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check,
                            size: 10,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Uploaded',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Submit button ─────────────────────────────────────────────────────────────
class _SubmitButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;
  final ThemeData theme;

  const _SubmitButton({
    required this.isLoading,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Submit for Verification',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
