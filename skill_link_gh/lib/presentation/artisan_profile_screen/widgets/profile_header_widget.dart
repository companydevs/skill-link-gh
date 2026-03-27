import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:skill_link_gh/widgets/user_avatar_widget.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final Map<String, dynamic> artisanData;

  const ProfileHeaderWidget({super.key, required this.artisanData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name =
        artisanData['fullName'] as String? ??
        artisanData['name'] as String? ??
        'Unknown';
    final location = artisanData['location'] as String? ?? '';
    final rating = (artisanData['rating'] as num?)?.toDouble() ?? 0.0;
    final totalReviews = artisanData['totalReviews'] as int? ?? 0;
    final isVerified =
        (artisanData['verificationBadges'] as Map?)?['identityVerified'] ==
        true;
    final categories = List<String>.from(
      artisanData['serviceCategories'] as List? ?? [],
    );
    final hourlyRate = artisanData['hourlyRate'];

    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + name row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              UserAvatarWidget(
                imageUrl: artisanData['profileImage'] as String?,
                name: name,
                size: 72,
                semanticLabel: 'Profile picture of $name',
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVerified) ...[
                          SizedBox(width: 1.5.w),
                          Icon(
                            Icons.verified,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                    if (location.isNotEmpty) ...[
                      SizedBox(height: 0.4.h),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          SizedBox(width: 1.w),
                          Flexible(
                            child: Text(
                              location,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: 0.6.h),
                    // Rating row
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Colors.amber[600],
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          rating.toStringAsFixed(1),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          ' ($totalReviews)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (hourlyRate != null) ...[
                          SizedBox(width: 3.w),
                          Text(
                            'GHS $hourlyRate/hr',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
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

          // Category chips
          if (categories.isNotEmpty) ...[
            SizedBox(height: 1.5.h),
            Wrap(
              spacing: 2.w,
              runSpacing: 0.8.h,
              children: categories
                  .take(4)
                  .map(
                    (c) => Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 0.4.h,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.6,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        c,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
