import 'dart:math';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_link_gh/domain/models/post_model.dart';

import '../../../core/app_export.dart';

class PostCardWidget extends StatefulWidget {
  final PostModel post;
  final VoidCallback onLike;
  final VoidCallback onBookNow;
  final VoidCallback onArtisanTap;
  final VoidCallback onLongPress;

  const PostCardWidget({
    super.key,
    required this.post,
    required this.onLike,
    required this.onBookNow,
    required this.onArtisanTap,
    required this.onLongPress,
  });

  @override
  State<PostCardWidget> createState() => _PostCardWidgetState();
}

class _PostCardWidgetState extends State<PostCardWidget>
    with TickerProviderStateMixin {
  int _currentImageIndex = 0;
  late int _likes;
  late bool _isLiked;

  // Heart animation
  late AnimationController _likeAnimationController;
  late Animation<double> _likeAnimation;
  bool _showLikeAnimation = false;

  // Floating hearts
  final List<_FloatingHeart> _hearts = [];

  // Firestore comment count stream
  Stream<int> get _commentsCountStream => FirebaseFirestore.instance
      .collection('posts')
      .doc(widget.post.id)
      .collection('comments')
      .snapshots()
      .map((snapshot) => snapshot.docs.length);

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLiked;
    _likes = widget.post.likes;

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
  void didUpdateWidget(PostCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update local state when post data changes from provider
    if (oldWidget.post.isLiked != widget.post.isLiked ||
        oldWidget.post.likes != widget.post.likes) {
      setState(() {
        _isLiked = widget.post.isLiked;
        _likes = widget.post.likes;
      });
    }
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    for (var heart in _hearts) {
      heart.controller.dispose();
    }
    super.dispose();
  }

  void _handleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likes += _isLiked ? 1 : -1;
      _showLikeAnimation = _isLiked;

      if (_isLiked) _addFloatingHearts();
    });

    _likeAnimationController.forward(from: 0).then((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _likeAnimationController.reverse();
          setState(() {
            _showLikeAnimation = false;
          });
        }
      });
    });

    // Firestore update
    widget.onLike();
  }

  void _handleDoubleTap() {
    if (!_isLiked) _handleLike();
  }

  void _addFloatingHearts() {
    final heartCount = 6;
    for (int i = 0; i < heartCount; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 800 + Random().nextInt(400)),
      );
      final animation = CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      );
      final heart = _FloatingHeart(
        animation: animation,
        controller: controller,
        startPosition: Offset(
          0.5 + (Random().nextDouble() - 0.5) * 0.4,
          0.8 + (Random().nextDouble() - 0.4) * 0.2,
        ),
        endPosition: Offset(0.5 + (Random().nextDouble() - 0.5) * 0.6, 0.2),
      );
      controller.forward();
      controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          controller.dispose();
          setState(() {
            _hearts.remove(heart);
          });
        }
      });
      _hearts.add(heart);
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
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
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
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
                imageUrl: widget.post.artisanImage.isNotEmpty
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
    ThemeData theme,
    List<PostImage> postImages,
    bool hasMultipleImages,
  ) {
    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
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
          ..._hearts.map((heart) {
            return Positioned(
              left: MediaQuery.of(context).size.width * heart.startPosition.dx,
              top: MediaQuery.of(context).size.height * heart.startPosition.dy,
              child: FadeTransition(
                opacity: heart.animation,
                child: Transform.translate(
                  offset: Offset(0, -150 * heart.animation.value),
                  child: CustomIconWidget(
                    iconName: 'favorite',
                    color: Colors.pinkAccent,
                    size: 24,
                  ),
                ),
              ),
            );
          }).toList(),
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Likes
              InkWell(
                onTap: _handleLike,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: _isLiked ? 'favorite' : 'favorite_border',
                        color: _isLiked
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        _likes.toString(),
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

              // Comments - Real-time count
              StreamBuilder<int>(
                stream: _commentsCountStream,
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return InkWell(
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/post-comment-screen',
                      arguments: widget.post,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 1.h,
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Row(
                            children: [
                              CustomIconWidget(
                                iconName: 'chat_bubble_outline',
                                color: theme.colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                            ],
                          ),
                          if (count > 0)
                            Positioned(
                              right: -6,
                              top: -6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  count.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const Spacer(),

              ElevatedButton(
                onPressed: widget.onBookNow,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 6.w,
                    vertical: 1.5.h,
                  ),
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

          // Liked by section
          if (widget.post.likedBy.isNotEmpty) ...[
            SizedBox(height: 1.h),
            _buildLikedBySection(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildLikedBySection(ThemeData theme) {
    final likedBy = widget.post.likedBy;
    final totalLikes = widget.post.likes;
    final othersCount = totalLikes - likedBy.length;

    return Padding(
      padding: EdgeInsets.only(left: 2.w, top: 0.5.h),
      child: Row(
        children: [
          // Profile images stack
          SizedBox(
            height: 24,
            width: likedBy.length > 1 ? 40 : 24,
            child: Stack(
              children: List.generate(likedBy.length > 2 ? 2 : likedBy.length, (
                index,
              ) {
                return Positioned(
                  left: index * 16.0,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: CustomImageWidget(
                        imageUrl: likedBy[index].userImage.isNotEmpty
                            ? likedBy[index].userImage
                            : 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
                        width: 24,
                        height: 24,
                        fit: BoxFit.cover,
                        semanticLabel: likedBy[index].userName,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          SizedBox(width: likedBy.length > 1 ? 3.w : 2.w),

          // Liked by text
          Expanded(
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                children: [
                  const TextSpan(text: 'Liked by '),
                  TextSpan(
                    text: likedBy[0].userName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (othersCount > 0)
                    TextSpan(
                      text:
                          ' and $othersCount ${othersCount == 1 ? 'other' : 'others'}',
                    ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// Floating heart model
class _FloatingHeart {
  final Animation<double> animation;
  final AnimationController controller;
  final Offset startPosition;
  final Offset endPosition;

  _FloatingHeart({
    required this.animation,
    required this.controller,
    required this.startPosition,
    required this.endPosition,
  });
}
