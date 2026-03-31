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
    final dailyRate = artisanData['dailyRate'] ?? artisanData['hourlyRate'];
    final coverPhoto = artisanData['coverPhoto'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Cover ────────────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          height: 15.h,
          child: coverPhoto != null && coverPhoto.isNotEmpty
              ? Image.network(
                  coverPhoto,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _coverFallback(theme),
                )
              : _coverFallback(theme),
        ),

        // ── Avatar row ───────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 0),
          child: Transform.translate(
            offset: const Offset(0, -28),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Avatar with border
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 3,
                    ),
                  ),
                  child: UserAvatarWidget(
                    imageUrl: artisanData['profileImage'] as String?,
                    name: name,
                    size: 72,
                    semanticLabel: 'Profile picture of $name',
                  ),
                ),
                const Spacer(),
                // Rate badge
                if (dailyRate != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.9,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'GHS $dailyRate / day',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // ── Name block (pulled up to close gap from translate) ───────
        Padding(
          padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 0),
          child: Transform.translate(
            offset: const Offset(0, -20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + verified
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.verified_rounded,
                        size: 17,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),

                // Location + rating on one line
                Row(
                  children: [
                    if (location.isNotEmpty) ...[
                      Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 2),
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
                      const SizedBox(width: 12),
                    ],
                    Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: Colors.amber[600],
                    ),
                    const SizedBox(width: 2),
                    Text(
                      rating.toStringAsFixed(1),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '  (${totalReviews})',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

                // Category chips
                if (categories.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: categories
                        .take(3)
                        .map((c) => _chip(c, theme))
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

  Widget _chip(String label, ThemeData theme) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  Widget _coverFallback(ThemeData theme) =>
      Container(color: theme.colorScheme.surfaceContainerHighest);
}
