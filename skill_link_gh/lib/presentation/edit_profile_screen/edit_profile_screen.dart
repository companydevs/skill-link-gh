import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';
import 'package:skill_link_gh/provider/profile_provider.dart';
import 'package:skill_link_gh/widgets/user_avatar_widget.dart';
import 'package:skill_link_gh/widgets/custom_app_toast.dart';
import 'package:skill_link_gh/widgets/custom_text_form_field.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Controllers
  final _fullNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _experienceController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _languagesController = TextEditingController();
  final _certificationsController = TextEditingController();

  // State
  File? _profileImage;
  File? _coverImage;
  List<String> _selectedSkills = [];
  List<String> _selectedCategories = [];
  List<File> _portfolioImages = [];
  Map<String, bool> _availability = {
    'Monday': false,
    'Tuesday': false,
    'Wednesday': false,
    'Thursday': false,
    'Friday': false,
    'Saturday': false,
    'Sunday': false,
  };
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);

  bool _isLoading = false;

  // Available options
  final List<String> _availableSkills = [
    'Plumbing',
    'Electrical',
    'Carpentry',
    'Painting',
    'Masonry',
    'Roofing',
    'Tiling',
    'Welding',
    'HVAC',
    'Landscaping',
    'Cleaning',
    'Catering',
    'Photography',
    'Tailoring',
    'Hair Styling',
    'Makeup',
    'Mechanic',
    'Electronics Repair',
    'Web Design',
    'Tutoring',
  ];

  final List<String> _availableCategories = [
    'Construction',
    'Home Services',
    'Beauty & Wellness',
    'Technology',
    'Education',
    'Food & Catering',
    'Transportation',
    'Creative Services',
    'Health Services',
    'Business Services',
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  void _loadCurrentProfile() {
    final profileState = ref.read(profileNotifierProvider);
    if (profileState.profileData != null) {
      final data = profileState.profileData!;
      _fullNameController.text = data["fullName"] as String? ?? '';
      _bioController.text = data["bio"] as String? ?? '';
      _locationController.text = data["location"] as String? ?? '';
      _phoneController.text = data["phoneNumber"] as String? ?? '';
      _experienceController.text = data["experience"] as String? ?? '';
      _hourlyRateController.text = data["hourlyRate"]?.toString() ?? '';
      _languagesController.text =
          (data["languages"] as List?)?.join(', ') ?? '';
      _certificationsController.text =
          (data["certifications"] as List?)?.join(', ') ?? '';

      _selectedSkills = List<String>.from(data["skills"] as List? ?? []);
      _selectedCategories = List<String>.from(
        data["serviceCategories"] as List? ?? [],
      );

      // Load availability
      final availability = data["availability"] as Map<String, dynamic>?;
      if (availability != null) {
        _availability = Map<String, bool>.from(availability);
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _experienceController.dispose();
    _hourlyRateController.dispose();
    _languagesController.dispose();
    _certificationsController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, {required bool isProfile}) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: isProfile ? 500 : 1200,
        maxHeight: isProfile ? 500 : 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          if (isProfile) {
            _profileImage = File(pickedFile.path);
          } else {
            _coverImage = File(pickedFile.path);
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

  Future<void> _pickPortfolioImages() async {
    try {
      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFiles.isNotEmpty) {
        setState(() {
          _portfolioImages.addAll(pickedFiles.map((file) => File(file.path)));
        });
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          message: 'Failed to pick portfolio images: $e',
          type: ToastType.error,
        );
      }
    }
  }

  void _showImageSourceDialog({required bool isProfile}) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera, isProfile: isProfile);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery, isProfile: isProfile);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSkillsDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Select Skills'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: _availableSkills.length,
              itemBuilder: (context, index) {
                final skill = _availableSkills[index];
                return CheckboxListTile(
                  title: Text(skill),
                  value: _selectedSkills.contains(skill),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedSkills.add(skill);
                      } else {
                        _selectedSkills.remove(skill);
                      }
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoriesDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Select Service Categories'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: _availableCategories.length,
              itemBuilder: (context, index) {
                final category = _availableCategories[index];
                return CheckboxListTile(
                  title: Text(category),
                  value: _selectedCategories.contains(category),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedCategories.add(category);
                      } else {
                        _selectedCategories.remove(category);
                      }
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime({required bool isStartTime}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<String?> _uploadImage(File file, String path) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final ref = FirebaseStorage.instance.ref('users/$uid/$path');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Upload images in parallel if changed
      final uploads = await Future.wait([
        if (_profileImage != null)
          _uploadImage(_profileImage!, 'profileImage.jpg')
        else
          Future.value(null),
        if (_coverImage != null)
          _uploadImage(_coverImage!, 'coverPhoto.jpg')
        else
          Future.value(null),
      ]);

      final profileImageUrl = uploads[0];
      final coverPhotoUrl = uploads[1];

      final profileData = {
        'fullName': _fullNameController.text.trim(),
        'bio': _bioController.text.trim(),
        'location': _locationController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'experience': _experienceController.text.trim(),
        'hourlyRate': double.tryParse(_hourlyRateController.text) ?? 0.0,
        'languages': _languagesController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        'certifications': _certificationsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        'skills': _selectedSkills,
        'serviceCategories': _selectedCategories,
        'availability': _availability,
        'workingHours': {
          'start':
              '${_startTime.hour}:${_startTime.minute.toString().padLeft(2, '0')}',
          'end':
              '${_endTime.hour}:${_endTime.minute.toString().padLeft(2, '0')}',
        },
        if (profileImageUrl != null) 'profileImage': profileImageUrl,
        if (coverPhotoUrl != null) 'coverPhoto': coverPhotoUrl,
      };

      await ref
          .read(profileNotifierProvider.notifier)
          .updateProfile(profileData);

      if (mounted) {
        AppToast.show(
          context,
          message: 'Profile updated successfully!',
          type: ToastType.success,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          message: 'Failed to update profile: $e',
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
    final profileState = ref.watch(profileNotifierProvider);
    final currentProfileData = profileState.profileData;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        variant: AppBarVariant.standard,
        title: 'Edit Profile',
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSection(theme, currentProfileData),
              SizedBox(height: 3.h),
              _buildBasicInfoSection(theme),
              SizedBox(height: 3.h),
              _buildSkillsAndCategoriesSection(theme),
              SizedBox(height: 3.h),
              _buildAvailabilitySection(theme),
              SizedBox(height: 3.h),
              _buildPortfolioSection(theme),
              SizedBox(height: 10.h), // Extra space for FAB
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(
    ThemeData theme,
    Map<String, dynamic>? currentData,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile Images',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),

        // Cover Photo
        Container(
          width: double.infinity,
          height: 20.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _coverImage != null
                    ? Image.file(
                        _coverImage!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : CustomImageWidget(
                        imageUrl:
                            currentData?["coverPhoto"] as String? ??
                            'https://images.unsplash.com/photo-1557804506-669a67965ba0?ixlib=rb-4.0.3&auto=format&fit=crop&w=1200&q=80',
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: FloatingActionButton.small(
                  heroTag: "cover_image_edit", // Add unique hero tag
                  onPressed: () => _showImageSourceDialog(isProfile: false),
                  backgroundColor: theme.colorScheme.surface.withValues(
                    alpha: 0.9,
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 2.h),

        // Profile Photo
        Center(
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: _profileImage != null
                    ? ClipOval(
                        child: Image.file(
                          _profileImage!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      )
                    : UserAvatarWidget(
                        imageUrl: currentData?["profileImage"] as String?,
                        name: currentData?["fullName"] as String? ?? 'User',
                        size: 120,
                      ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: FloatingActionButton.small(
                  heroTag: "profile_image_edit", // Add unique hero tag
                  onPressed: () => _showImageSourceDialog(isProfile: true),
                  backgroundColor: theme.colorScheme.primary,
                  child: const Icon(Icons.camera_alt, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Information',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),

        CustomTextFormField(
          controller: _fullNameController,
          hintText: 'Full Name',
          validator: (value) =>
              value?.isEmpty == true ? 'Please enter your full name' : null,
        ),
        SizedBox(height: 2.h),

        CustomTextFormField(
          controller: _bioController,
          hintText: 'Bio (Tell clients about yourself)',
          maxLines: 4,
          validator: (value) =>
              value?.isEmpty == true ? 'Please enter a bio' : null,
        ),
        SizedBox(height: 2.h),

        CustomTextFormField(
          controller: _locationController,
          hintText: 'Location (City, Region)',
          validator: (value) =>
              value?.isEmpty == true ? 'Please enter your location' : null,
        ),
        SizedBox(height: 2.h),

        CustomTextFormField(
          controller: _phoneController,
          hintText: 'Phone Number',
          keyboardType: TextInputType.phone,
          validator: (value) =>
              value?.isEmpty == true ? 'Please enter your phone number' : null,
        ),
        SizedBox(height: 2.h),

        Row(
          children: [
            Expanded(
              child: CustomTextFormField(
                controller: _experienceController,
                hintText: 'Years of Experience',
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: CustomTextFormField(
                controller: _hourlyRateController,
                hintText: 'Hourly Rate (GHS)',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),

        CustomTextFormField(
          controller: _languagesController,
          hintText: 'Languages (comma separated)',
        ),
        SizedBox(height: 2.h),

        CustomTextFormField(
          controller: _certificationsController,
          hintText: 'Certifications (comma separated)',
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildSkillsAndCategoriesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Skills & Categories',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),

        // Skills
        InkWell(
          onTap: _showSkillsDialog,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Skills', style: theme.textTheme.bodyLarge),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                if (_selectedSkills.isNotEmpty) ...[
                  SizedBox(height: 1.h),
                  Wrap(
                    spacing: 2.w,
                    runSpacing: 1.h,
                    children: _selectedSkills
                        .map(
                          (skill) => Chip(
                            label: Text(
                              skill,
                              style: theme.textTheme.bodySmall,
                            ),
                            backgroundColor: theme.colorScheme.primaryContainer,
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() => _selectedSkills.remove(skill));
                            },
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),

        SizedBox(height: 2.h),

        // Categories
        InkWell(
          onTap: _showCategoriesDialog,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Service Categories',
                      style: theme.textTheme.bodyLarge,
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                if (_selectedCategories.isNotEmpty) ...[
                  SizedBox(height: 1.h),
                  Wrap(
                    spacing: 2.w,
                    runSpacing: 1.h,
                    children: _selectedCategories
                        .map(
                          (category) => Chip(
                            label: Text(
                              category,
                              style: theme.textTheme.bodySmall,
                            ),
                            backgroundColor:
                                theme.colorScheme.secondaryContainer,
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(
                                () => _selectedCategories.remove(category),
                              );
                            },
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilitySection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Availability & Working Hours',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),

        // Working Hours
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectTime(isStartTime: true),
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Start Time', style: theme.textTheme.bodySmall),
                      SizedBox(height: 0.5.h),
                      Text(
                        _startTime.format(context),
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: InkWell(
                onTap: () => _selectTime(isStartTime: false),
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('End Time', style: theme.textTheme.bodySmall),
                      SizedBox(height: 0.5.h),
                      Text(
                        _endTime.format(context),
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 2.h),

        // Available Days
        Text('Available Days', style: theme.textTheme.bodyLarge),
        SizedBox(height: 1.h),

        ...[
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday',
        ].map(
          (day) => CheckboxListTile(
            title: Text(day),
            value: _availability[day] ?? false,
            onChanged: (bool? value) {
              setState(() {
                _availability[day] = value ?? false;
              });
            },
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _buildPortfolioSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Portfolio Images',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton.icon(
              onPressed: _pickPortfolioImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Add Images'),
            ),
          ],
        ),
        SizedBox(height: 2.h),

        if (_portfolioImages.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _portfolioImages.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _portfolioImages[index],
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _portfolioImages.removeAt(index);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          )
        else
          Container(
            width: double.infinity,
            height: 15.h,
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.photo_library,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                SizedBox(height: 1.h),
                Text(
                  'No portfolio images added yet',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
