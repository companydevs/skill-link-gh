import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/user_avatar_widget.dart';

/// Artisan card widget displaying profile information and quick actions
class ArtisanCardWidget extends StatelessWidget {
  final Map<String, dynamic> artisan;
  final VoidCallback onViewProfile;
  final VoidCallback onMessage;
  final VoidCallback onBookNow;

  const ArtisanCardWidget({
    super.key,
    required this.artisan,
    required this.onViewProfile,
    required this.onMessage,
    required this.onBookNow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onViewProfile,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: UserAvatarWidget(
                      imageUrl: artisan['profileImage'] as String?,
                      name: artisan['name'] as String,
                      size: 15.w,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                artisan['name'] as String,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (artisan['isVerified'] == true)
                              Container(
                                padding: EdgeInsets.all(0.5.w),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: CustomIconWidget(
                                  iconName: 'verified',
                                  color: theme.colorScheme.onPrimary,
                                  size: 16,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          (artisan['services'] as List).join(', '),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 1.h),
                        Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'star',
                              color: Colors.amber,
                              size: 16,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              '${artisan['rating']}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 3.w),
                            CustomIconWidget(
                              iconName: 'location_on',
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 16,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              '${artisan['distance']} km',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: artisan['isAvailable'] == true
                          ? theme.colorScheme.tertiary.withValues(alpha: 0.1)
                          : theme.colorScheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: artisan['isAvailable'] == true
                                ? theme.colorScheme.tertiary
                                : theme.colorScheme.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          artisan['isAvailable'] == true ? 'Available' : 'Busy',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: artisan['isAvailable'] == true
                                ? theme.colorScheme.tertiary
                                : theme.colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: onMessage,
                    icon: CustomIconWidget(
                      iconName: 'chat_bubble_outline',
                      color: theme.colorScheme.primary,
                      size: 18,
                    ),
                    label: Text('Message'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 1.h,
                      ),
                      minimumSize: Size(20.w, 5.h),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  ElevatedButton(
                    onPressed: onBookNow,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 1.h,
                      ),
                      minimumSize: Size(20.w, 5.h),
                    ),
                    child: Text('Book Now'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
