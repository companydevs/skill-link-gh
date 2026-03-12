import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'shimmer_widget.dart';

/// Shimmer loading widget that matches the exact structure of PostCardWidget
class PostShimmerWidget extends StatelessWidget {
  const PostShimmerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: ShimmerWidget(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderShimmer(theme),
            _buildImageShimmer(theme),
            _buildContentShimmer(theme),
            _buildActionsShimmer(theme),
          ],
        ),
      ),
    );
  }

  /// Header shimmer matching the artisan profile section
  Widget _buildHeaderShimmer(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Row(
        children: [
          // Profile image shimmer
          ShimmerContainer(
            width: 40,
            height: 40,
            borderRadius: BorderRadius.circular(20),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Artisan name shimmer
                ShimmerContainer(
                  width: 35.w,
                  height: 16,
                  borderRadius: BorderRadius.circular(8),
                ),
                SizedBox(height: 0.5.h),
                // Time and location shimmer
                ShimmerContainer(
                  width: 25.w,
                  height: 12,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
          ),
          // More options button shimmer
          ShimmerContainer(
            width: 24,
            height: 24,
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
    );
  }

  /// Image carousel shimmer
  Widget _buildImageShimmer(ThemeData theme) {
    return Column(
      children: [
        // Main image shimmer
        ShimmerContainer(
          width: double.infinity,
          height: 250,
          borderRadius: BorderRadius.circular(
            0,
          ), // No border radius for full width
        ),
        SizedBox(height: 1.h),
        // Image indicators shimmer (for carousel)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            3, // Simulate 3 image indicators
            (index) => Container(
              margin: EdgeInsets.symmetric(horizontal: 0.5.w),
              child: ShimmerContainer(
                width: 8,
                height: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Content shimmer matching the post description and details
  Widget _buildContentShimmer(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post title/description shimmer (multiple lines)
          ShimmerContainer(
            width: double.infinity,
            height: 16,
            borderRadius: BorderRadius.circular(8),
          ),
          SizedBox(height: 1.h),
          ShimmerContainer(
            width: 80.w,
            height: 16,
            borderRadius: BorderRadius.circular(8),
          ),
          SizedBox(height: 1.h),
          ShimmerContainer(
            width: 60.w,
            height: 16,
            borderRadius: BorderRadius.circular(8),
          ),
          SizedBox(height: 2.h),
          // Service details shimmer
          Row(
            children: [
              // Price shimmer
              ShimmerContainer(
                width: 20.w,
                height: 20,
                borderRadius: BorderRadius.circular(10),
              ),
              SizedBox(width: 4.w),
              // Category shimmer
              ShimmerContainer(
                width: 25.w,
                height: 20,
                borderRadius: BorderRadius.circular(10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Actions shimmer matching the like, comment, share, and book buttons
  Widget _buildActionsShimmer(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        children: [
          // Like and comment counts shimmer
          Row(
            children: [
              ShimmerContainer(
                width: 15.w,
                height: 14,
                borderRadius: BorderRadius.circular(7),
              ),
              SizedBox(width: 4.w),
              ShimmerContainer(
                width: 18.w,
                height: 14,
                borderRadius: BorderRadius.circular(7),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          // Action buttons shimmer
          Row(
            children: [
              // Like button shimmer
              ShimmerContainer(
                width: 24,
                height: 24,
                borderRadius: BorderRadius.circular(12),
              ),
              SizedBox(width: 4.w),
              // Comment button shimmer
              ShimmerContainer(
                width: 24,
                height: 24,
                borderRadius: BorderRadius.circular(12),
              ),
              SizedBox(width: 4.w),
              // Share button shimmer
              ShimmerContainer(
                width: 24,
                height: 24,
                borderRadius: BorderRadius.circular(12),
              ),
              const Spacer(),
              // Book now button shimmer
              ShimmerContainer(
                width: 25.w,
                height: 36,
                borderRadius: BorderRadius.circular(18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Multiple post shimmers for the loading state
class PostsShimmerList extends StatelessWidget {
  final int itemCount;

  const PostsShimmerList({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      itemCount: itemCount,
      itemBuilder: (context, index) => const PostShimmerWidget(),
    );
  }
}
