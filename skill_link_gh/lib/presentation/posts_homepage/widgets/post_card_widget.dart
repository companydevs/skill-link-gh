import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:skill_link_gh/domain/models/post_model.dart';

import '../../../core/app_export.dart';

class PostCardWidget extends StatefulWidget {
  final PostModel post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onBookNow;
  final VoidCallback onArtisanTap;
  final VoidCallback onPostTap;
  final VoidCallback onLongPress;

  const PostCardWidget({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onBookNow,
    required this.onArtisanTap,
    required this.onPostTap,
    required this.onLongPress,
  });

  @override
  State<PostCardWidget> createState() => _PostCardWidgetState();
}

class _PostCardWidgetState extends State<PostCardWidget>
    with SingleTickerProviderStateMixin {
  int _currentImageIndex = 0;
  late AnimationController _likeAnimationController;
  late Animation<double> _likeAnimation;
  bool _showLikeAnimation = false;

  @override
  void initState() {
    super.initState();
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _likeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _likeAnimationController,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (!widget.post.isLiked) {
      widget.onLike();
      setState(() {
        _showLikeAnimation = true;
      });
      _likeAnimationController.forward().then((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _likeAnimationController.reverse();
            setState(() {
              _showLikeAnimation = false;
            });
          }
        });
      });
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final postImages = widget.post.postImages;
    final hasMultipleImages = postImages.length > 1;

    return GestureDetector(
      onLongPress: widget.onLongPress,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            _buildImageCarousel(theme, postImages, hasMultipleImages),
            _buildContent(theme),
            _buildActions(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return InkWell(
      onTap: widget.onArtisanTap,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Row(
          children: [
            ClipOval(
              child: CustomImageWidget(
  imageUrl: (widget.post.artisanImage.isNotEmpty)
      ? widget.post.artisanImage
      : 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
  width: 40,
  height: 40,
  fit: BoxFit.cover,
  semanticLabel: widget.post.artisanName,
),

            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.post.artisanName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.post.serviceCategory,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        _getTimeAgo(widget.post.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: CustomIconWidget(
                iconName: 'more_vert',
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
              onPressed: widget.onLongPress,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel(
      ThemeData theme, List<PostImage> postImages, bool hasMultipleImages) {
    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      onTap: widget.onPostTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          hasMultipleImages
              ? CarouselSlider(
                  options: CarouselOptions(
                    height: 250,
                    viewportFraction: 1.0,
                    enableInfiniteScroll: false,
                    onPageChanged: (index, reason) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                  ),
                  items: postImages.map((image) {
                    return CustomImageWidget(
                      imageUrl: image.url,
                      width: double.infinity,
                      height: 250,
                      fit: BoxFit.cover,
                      semanticLabel: image.label,
                    );
                  }).toList(),
                )
              : CustomImageWidget(
                  imageUrl: postImages[0].url,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                  semanticLabel: postImages[0].label,
                ),
          if (hasMultipleImages)
            Positioned(
              bottom: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  postImages.length,
                  (index) => Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentImageIndex == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
          if (_showLikeAnimation)
            ScaleTransition(
              scale: _likeAnimation,
              child: CustomIconWidget(
                iconName: 'favorite',
                color: Colors.white,
                size: 80,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.post.description,
            style: theme.textTheme.bodyMedium,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              CustomIconWidget(
                iconName: 'payments',
                color: theme.colorScheme.secondary,
                size: 16,
              ),
              SizedBox(width: 1.w),
              Text(
                widget.post.pricing,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions(ThemeData theme) {
    final isLiked = widget.post.isLiked;
    final likes = widget.post.likes;
    final comments = widget.post.comments;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        children: [
          InkWell(
            onTap: widget.onLike,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: isLiked ? 'favorite' : 'favorite_border',
                    color: isLiked
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    likes.toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 4.w),
          InkWell(
            onTap: widget.onComment,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'chat_bubble_outline',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    comments.toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: widget.onBookNow,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
              minimumSize: Size(0, 5.h),
            ),
            child: Text(
              'Book Now',
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
