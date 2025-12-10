import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Profile header widget displaying cover photo, profile image, and basic info
class ProfileHeaderWidget extends StatelessWidget {
  final Map<String, dynamic> artisanData;

  const ProfileHeaderWidget({
    super.key,
    required this.artisanData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Cover Photo
        CustomImageWidget(
          imageUrl: artisanData["coverPhoto"] as String,
          width: 100.w,
          height: 30.h,
          fit: BoxFit.cover,
          semanticLabel: artisanData["coverPhotoSemanticLabel"] as String,
        ),
        // Gradient Overlay
        Container(
          width: 100.w,
          height: 30.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.7),
              ],
            ),
          ),
        ),
        // Profile Content
        Positioned(
          bottom: -8.h,
          left: 0,
          right: 0,
          child: Column(
            children: [
              // Profile Image
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(60),
                  child: CustomImageWidget(
                    imageUrl: artisanData["profileImage"] as String,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    semanticLabel:
                        artisanData["profileImageSemanticLabel"] as String,
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              // Name and Categories
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Column(
                  children: [
                    Text(
                      artisanData["name"] as String,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 1.h),
                    Wrap(
                      spacing: 2.w,
                      runSpacing: 1.h,
                      alignment: WrapAlignment.center,
                      children: (artisanData["serviceCategories"] as List)
                          .map((category) => Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 3.w,
                                  vertical: 0.5.h,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  category as String,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    SizedBox(height: 1.5.h),
                    // Rating and Verification
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: 'star',
                          size: 20,
                          color: theme.colorScheme.secondary,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          '${artisanData["rating"]} (${artisanData["totalReviews"]} reviews)',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if ((artisanData["verificationBadges"]
                                as Map)["identityVerified"] ==
                            true) ...[
                          SizedBox(width: 2.w),
                          Container(
                            padding: EdgeInsets.all(0.5.w),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: CustomIconWidget(
                              iconName: 'verified',
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
