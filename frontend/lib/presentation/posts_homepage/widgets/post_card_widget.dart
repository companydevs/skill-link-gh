import 'dart:math';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sizer/sizer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_link_gh/domain/models/post_model.dart';

import '../../../core/app_export.dart';
import '../../../widgets/user_avatar_widget.dart';

class PostCardWidget extends StatefulWidget {
  final PostModel post;
  final VoidCallback onLike;
  final VoidCallback onBookNow;
  final VoidCallback onArtisanTap;
  final VoidCallback onLongPress;
  final VoidCallback? onSave;

  const PostCardWidget({
    super.key,
    required this.post,
    required this.onLike,
    required this.onBookNow,
    required this.onArtisanTap,
    required this.onLongPress,
    this.onSave,
  });

  @override
  State<PostCardWidget> createState() => _PostCardWidgetState();
}

class _PostCardWidgetState extends State<PostCardWidget>
    with TickerProviderStateMixin {
  int _currentImageIndex = 0;
  late int _likes;
  late bool _isLiked;
  late bool _isSaved;

  late AnimationController _likeAnimationController;
  late Animation<double> _likeAnimation;
  bool _showLikeAnimation = false;

  final List<_FloatingHeart> _hearts = [];

  Stream<int> get _commentsCountStream => FirebaseFirestore.instance
      .collection('posts')
      .doc(widget.post.id)
      .collection('comments')
      .snapshots()
      .map((s) => s.docs.length);

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLiked;
    _isSaved = widget.post.isSaved;
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
    if (oldWidget.post.isLiked != widget.post.isLiked ||
        oldWidget.post.likes != widget.post.likes) {
      setState(() {
        _isLiked = widget.post.isLiked;
        _likes = widget.post.likes;
      });
    }
    if (oldWidget.post.isSaved != widget.post.isSaved) {
      setState(() => _isSaved = widget.post.isSaved);
    }
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    for (final h in _hearts) {
      h.controller.dispose();
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
          setState(() => _showLikeAnimation = false);
        }
      });
    });
    widget.onLike();
  }

  void _handleDoubleTap() {
    if (!_isLiked) _handleLike();
  }

  void _handleSave() {
    setState(() => _isSaved = !_isSaved);
    widget.onSave?.call();
  }

  void _addFloatingHearts() {
    for (int i = 0; i < 6; i++) {
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
          if (mounted) setState(() => _hearts.remove(heart));
        }
      });
      _hearts.add(heart);
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 14) return 'Last week';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    if (diff.inDays < 60) return 'A month ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} months ago';
    if (diff.inDays < 730) return 'A year ago';
    return '${(diff.inDays / 365).floor()} years ago';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final postImages = widget.post.postImages;
    final hasMultiple = postImages.length > 1;

    return Container(
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          _buildImageArea(theme, postImages, hasMultiple),
          _buildActionBar(theme),
          _buildLikesRow(theme),
          _buildCaption(theme),
          _buildCommentPreview(theme),
          _buildTimestamp(theme),
          const SizedBox(height: 8),
          Divider(
            height: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.12),
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onArtisanTap,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.primary, width: 2),
              ),
              padding: const EdgeInsets.all(2),
              child: ClipOval(
                child: CustomImageWidget(
                  imageUrl: widget.post.artisanImage.isNotEmpty
                      ? widget.post.artisanImage
                      : kDefaultMaleAvatar,
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  semanticLabel: widget.post.artisanName,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: widget.onArtisanTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.post.artisanName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.post.serviceCategory,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.more_horiz,
              color: theme.colorScheme.onSurface,
              size: 22,
            ),
            onPressed: widget.onLongPress,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ── Image area ───────────────────────────────────────────────────────────────
  Widget _buildImageArea(
    ThemeData theme,
    List<PostImage> images,
    bool hasMultiple,
  ) {
    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          hasMultiple
              ? CarouselSlider(
                  options: CarouselOptions(
                    height: 100.w, // square like Instagram
                    viewportFraction: 1.0,
                    enableInfiniteScroll: false,
                    onPageChanged: (i, _) =>
                        setState(() => _currentImageIndex = i),
                  ),
                  items: images
                      .map(
                        (img) => CustomImageWidget(
                          imageUrl: img.url,
                          width: double.infinity,
                          height: 100.w,
                          fit: BoxFit.cover,
                          semanticLabel: img.label,
                        ),
                      )
                      .toList(),
                )
              : CustomImageWidget(
                  imageUrl: images[0].url,
                  width: double.infinity,
                  height: 100.w,
                  fit: BoxFit.cover,
                  semanticLabel: images[0].label,
                ),

          // Dot indicators
          if (hasMultiple)
            Positioned(
              bottom: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _currentImageIndex == i ? 16 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: _currentImageIndex == i
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),

          // Multi-image counter badge
          if (hasMultiple)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentImageIndex + 1}/${images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          // Double-tap heart animation
          if (_showLikeAnimation)
            ScaleTransition(
              scale: _likeAnimation,
              child: const Icon(Icons.favorite, color: Colors.white, size: 90),
            ),

          // Floating hearts
          ..._hearts.map(
            (heart) => Positioned(
              left: MediaQuery.of(context).size.width * heart.startPosition.dx,
              top: MediaQuery.of(context).size.height * heart.startPosition.dy,
              child: FadeTransition(
                opacity: heart.animation,
                child: Transform.translate(
                  offset: Offset(0, -150 * heart.animation.value),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.pinkAccent,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Action bar (Instagram-style) ─────────────────────────────────────────────
  Widget _buildActionBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // Like — Instagram red heart
          _ActionBtn(
            icon: _isLiked
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: _isLiked
                ? const Color(0xFFED4956)
                : theme.colorScheme.onSurface,
            onTap: _handleLike,
          ),
          if (_likes > 0) ...[
            const SizedBox(width: 2),
            Text(
              '$_likes',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
          const SizedBox(width: 12),
          // Comment — with live count next to icon
          StreamBuilder<int>(
            stream: _commentsCountStream,
            builder: (_, snap) {
              final count = snap.data ?? 0;
              return GestureDetector(
                onTap: () => Navigator.pushNamed(
                  context,
                  '/post-comment-screen',
                  arguments: widget.post,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: SvgPicture.asset(
                        'assets/images/comment-1-svgrepo-com.svg',
                        width: 26,
                        height: 26,
                        colorFilter: ColorFilter.mode(
                          theme.colorScheme.onSurface,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 2),
                      Text(
                        '$count',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          // Share — custom SVG
          GestureDetector(
            onTap: widget.onLongPress,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: SvgPicture.asset(
                'assets/images/send-svgrepo-com.svg',
                width: 26,
                height: 26,
                colorFilter: ColorFilter.mode(
                  theme.colorScheme.onSurface,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const Spacer(),
          // Bookmark — Instagram ribbon bookmark
          _ActionBtn(
            icon: _isSaved
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            color: theme.colorScheme.onSurface,
            onTap: _handleSave,
          ),
        ],
      ),
    );
  }

  // ── Likes row ────────────────────────────────────────────────────────────────
  Widget _buildLikesRow(ThemeData theme) {
    if (_likes == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Text(
        '$_likes ${_likes == 1 ? 'like' : 'likes'}',
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ── Caption ──────────────────────────────────────────────────────────────────
  Widget _buildCaption(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.bodySmall,
          children: [
            TextSpan(
              text: '${widget.post.artisanName}  ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: widget.post.description),
          ],
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // ── Comment preview ──────────────────────────────────────────────────────────
  Widget _buildCommentPreview(ThemeData theme) {
    return StreamBuilder<int>(
      stream: _commentsCountStream,
      builder: (_, snap) {
        final count = snap.data ?? 0;
        if (count == 0) return const SizedBox.shrink();
        return GestureDetector(
          onTap: () => Navigator.pushNamed(
            context,
            '/post-comment-screen',
            arguments: widget.post,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            child: Text(
              'View all $count comments',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Pricing + Book Now + Timestamp ───────────────────────────────────────────
  Widget _buildTimestamp(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          // Pricing chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.payments_outlined,
                  size: 12,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.post.pricing,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Book Now
          GestureDetector(
            onTap: widget.onBookNow,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Book Now',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const Spacer(),
          Text(
            _getTimeAgo(widget.post.createdAt),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small action button ───────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 26, color: color),
      ),
    );
  }
}

// ── Floating heart model ──────────────────────────────────────────────────────
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
