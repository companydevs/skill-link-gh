import 'package:flutter/material.dart';
import 'package:skill_link_gh/widgets/user_avatar_widget.dart';

class ArtisanSummaryWidget extends StatelessWidget {
  final Map<String, dynamic> artisanData;

  const ArtisanSummaryWidget({super.key, required this.artisanData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final name =
        artisanData['name'] as String? ??
        artisanData['fullName'] as String? ??
        'Unknown Artisan';
    final serviceType =
        artisanData['serviceType'] as String? ??
        (artisanData['services'] as List?)?.join(', ') ??
        '';
    final rating = (artisanData['rating'] as num?)?.toDouble() ?? 0.0;
    final reviews =
        artisanData['reviews'] as int? ??
        artisanData['totalReviews'] as int? ??
        0;
    final profileImage = artisanData['profileImage'] as String? ?? '';

    // Price display — prefer dailyRate, then priceRange
    final dailyRate = artisanData['dailyRate'] ?? artisanData['hourlyRate'];
    final priceRange = artisanData['priceRange'] as String?;
    String priceLabel = '';
    if (dailyRate != null) {
      priceLabel = 'GHS $dailyRate/day';
    } else if (priceRange != null && priceRange.isNotEmpty) {
      priceLabel = priceRange;
    }

    if (artisanData.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: UserAvatarWidget(
              imageUrl: profileImage,
              name: name,
              size: 60,
              semanticLabel: 'Profile photo of $name',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (serviceType.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    serviceType,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: Colors.amber[600],
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '$rating${reviews > 0 ? ' ($reviews)' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (priceLabel.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Rate',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  priceLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
