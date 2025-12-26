import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Reviews section widget displaying client feedback and ratings
class ReviewsSectionWidget extends StatelessWidget {
  final List<Map<String, dynamic>> reviews;
  final double averageRating;
  final int totalReviews;

  const ReviewsSectionWidget({
    super.key,
    required this.reviews,
    required this.averageRating,
    required this.totalReviews,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating Summary
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Column(
                  children: [
                    Text(
                      averageRating.toStringAsFixed(1),
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (index) => CustomIconWidget(
                          iconName: index < averageRating.floor()
                              ? 'star'
                              : 'star_border',
                          size: 16,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      '$totalReviews reviews',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Column(
                    children: [
                      _buildRatingBar(context, 5, 85),
                      _buildRatingBar(context, 4, 10),
                      _buildRatingBar(context, 3, 3),
                      _buildRatingBar(context, 2, 1),
                      _buildRatingBar(context, 1, 1),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),
          // Reviews List
          Text(
            'Client Reviews',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          ...reviews.map((review) => _buildReviewCard(context, review)),
          SizedBox(height: 10.h),
        ],
      ),
    );
  }

  Widget _buildRatingBar(BuildContext context, int stars, int percentage) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        children: [
          Text('$stars', style: theme.textTheme.bodySmall),
          SizedBox(width: 2.w),
          CustomIconWidget(
            iconName: 'star',
            size: 12,
            color: theme.colorScheme.secondary,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: theme.colorScheme.outline.withValues(
                  alpha: 0.2,
                ),
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.secondary,
                ),
                minHeight: 6,
              ),
            ),
          ),
          SizedBox(width: 2.w),
          Text('$percentage%', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildReviewCard(BuildContext context, Map<String, dynamic> review) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: 3.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CustomImageWidget(
                  imageUrl: review["clientAvatar"] as String,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  semanticLabel: review["clientAvatarSemanticLabel"] as String,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review["clientName"] as String,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatDate(
                        review["date"] as String? ??
                            DateTime.now().toIso8601String(),
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'star',
                    size: 16,
                    color: theme.colorScheme.secondary,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    (review["rating"] as double).toStringAsFixed(1),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              review["service"] as String,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            review["review"] as String,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          if (review["images"] != null) ...[
            SizedBox(height: 2.h),
            SizedBox(
              height: 15.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: (review["images"] as List).length,
                separatorBuilder: (context, index) => SizedBox(width: 2.w),
                itemBuilder: (context, index) {
                  final image = (review["images"] as List)[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CustomImageWidget(
                      imageUrl: image["url"] as String,
                      width: 20.w,
                      height: 15.h,
                      fit: BoxFit.cover,
                      semanticLabel: image["semanticLabel"] as String,
                    ),
                  );
                },
              ),
            ),
          ],
          SizedBox(height: 2.h),
          Row(
            children: [
              TextButton.icon(
                onPressed: () {},
                icon: CustomIconWidget(
                  iconName: 'thumb_up_outlined',
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                label: Text('Helpful (${review["helpful"]})'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }
}
