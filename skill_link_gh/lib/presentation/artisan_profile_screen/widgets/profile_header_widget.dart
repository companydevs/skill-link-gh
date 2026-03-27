import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:skill_link_gh/widgets/user_avatar_widget.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final Map<String, dynamic> artisanData;

  const ProfileHeaderWidget({super.key, required this.artisanData});

  static const double _avatarRadius = 48.0;

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
    final coverPhoto = artisanData['coverPhoto'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Cover + avatar stack ──────────────────────────────────────
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Cover photo
            Container(
              width: double.infinity,
              height: 18.h,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
              ),
              child: coverPhoto != null && coverPhoto.isNotEmpty
                  ? Image.network(
                      coverPhoto,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _coverPlaceholder(theme),
                    )
                  : _coverPlaceholder(theme),
            ),

            // Avatar — sits half outside the bottom of the cover
            Positioned(
              bottom: -_avatarRadius,
              left: 4.w,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: UserAvatarWidget(
                  imageUrl: artisanData['profileImage'] as String?,
                  name: name,
                  size: _avatarRadius * 2,
                  semanticLabel: 'Profile picture of $name',
                ),
              ),
            ),
          ],
        ),

        // Space to clear the avatar overhang
        SizedBox(height: _avatarRadius + 8),

        // ── Name / info block ─────────────────────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name + verified badge
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
                    const SizedBox(width: 6),
                    Icon(
                      Icons.verified,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ],
              ),

              // Location
              if (location.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 3),
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

              const SizedBox(height: 6),

              // Rating + price
              Row(
                children: [
                  Icon(Icons.star_rounded, size: 16, color: Colors.amber[600]),
                  const SizedBox(width: 3),
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
                    const SizedBox(width: 12),
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

              // Category chips
              if (categories.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: categories
                      .take(4)
                      .map(
                        (c) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.6),
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

              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }

  Widget _coverPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primaryContainer,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 40,
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
