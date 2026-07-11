import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';
import 'package:skill_link_gh/domain/models/post_model.dart';
import 'package:skill_link_gh/presentation/posts_homepage/widgets/filter_bottom_sheet_widget.dart';
import 'package:skill_link_gh/provider/post_provider.dart';
import 'package:skill_link_gh/provider/notifications_provider.dart';
import 'package:skill_link_gh/widgets/custom_app_toast.dart';
import 'package:skill_link_gh/widgets/post_shimmer_widget.dart';

import '../../core/app_export.dart';
import '../../widgets/unified_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/post_card_widget.dart';

class PostsHomepage extends ConsumerStatefulWidget {
  const PostsHomepage({super.key});

  @override
  ConsumerState<PostsHomepage> createState() => _PostsHomepageState();
}

class _PostsHomepageState extends ConsumerState<PostsHomepage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  // Filter state
  double _locationRadius = 10.0;
  Set<String> _selectedCategories = {};
  RangeValues _priceRange = const RangeValues(0, 1000);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(postsNotifierProvider.notifier).loadInitialPosts();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final notifier = ref.read(postsNotifierProvider.notifier);
    final postsState = ref.read(postsNotifierProvider);
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !postsState.isLoading &&
        postsState.hasMore) {
      notifier.loadMorePosts();
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheetWidget(
        locationRadius: _locationRadius,
        selectedCategories: _selectedCategories,
        priceRange: _priceRange,
        onApplyFilters: (radius, categories, priceRange) {
          setState(() {
            _locationRadius = radius;
            _selectedCategories = categories;
            _priceRange = priceRange;
          });
          _applyFilters();
        },
      ),
    );
  }

  void _applyFilters() {
    final notifier = ref.read(postsNotifierProvider.notifier);
    notifier.refreshPosts();
  }

  void _navigateToArtisanProfile(PostModel post) {
    Navigator.pushNamed(
      context,
      '/artisan-profile-screen',
      arguments: post.toJson(),
    );
  }

  void _navigateToBooking(PostModel post) {
    Navigator.pushNamed(
      context,
      '/service-booking-screen',
      arguments: post.toJson(),
    );
  }

  void _navigateToSearch() {
    Navigator.pushNamed(context, '/search-and-discovery-screen');
  }

  void _showPostOptions(PostModel post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isSaved = post.isSaved;
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Save Post
                ListTile(
                  leading: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: isSaved
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                  title: Text(
                    isSaved ? 'Unsave Post' : 'Save Post',
                    style: theme.textTheme.bodyLarge,
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ref
                        .read(postsNotifierProvider.notifier)
                        .toggleSave(post.id);
                    if (mounted) {
                      AppToast.show(
                        context,
                        message: isSaved
                            ? 'Post removed from saved'
                            : 'Post saved',
                        type: ToastType.success,
                      );
                    }
                  },
                ),
                // Share
                ListTile(
                  leading: Icon(
                    Icons.share,
                    color: theme.colorScheme.onSurface,
                  ),
                  title: Text('Share', style: theme.textTheme.bodyLarge),
                  onTap: () {
                    Navigator.pop(ctx);
                    final text =
                        '${post.artisanName} — ${post.serviceCategory}\n${post.description}\n\nBooked via SkillLink GH';
                    Share.share(
                      text,
                      subject: '${post.artisanName} on SkillLink GH',
                    );
                  },
                ),
                // Report
                ListTile(
                  leading: Icon(
                    Icons.flag_outlined,
                    color: theme.colorScheme.error,
                  ),
                  title: Text(
                    'Report',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showReportDialog(post);
                  },
                ),
                SizedBox(height: 2.h),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showReportDialog(PostModel post) {
    final reasons = [
      'Spam or misleading',
      'Inappropriate content',
      'Fake profile',
      'Harassment',
      'Other',
    ];
    String? selected;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Report Post'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: reasons
                .map(
                  (r) => RadioListTile<String>(
                    value: r,
                    groupValue: selected,
                    title: Text(r),
                    onChanged: (v) => setS(() => selected = v),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                )
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selected == null
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      await ref
                          .read(postsNotifierProvider.notifier)
                          .reportPost(post.id, selected!);
                      if (mounted) {
                        AppToast.show(
                          context,
                          message: 'Post reported. Thanks for letting us know.',
                          type: ToastType.success,
                        );
                      }
                    },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final postsState = ref.watch(postsNotifierProvider);
    final notifier = ref.watch(postsNotifierProvider.notifier);
    final unreadCountAsync = ref.watch(unreadCountStreamProvider);

    // Debug logging
    print(
      '🏠 PostsHomepage build - posts: ${postsState.posts.length}, isLoading: ${postsState.isLoading}',
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'location_on',
              color: theme.colorScheme.primary,
              size: 20,
            ),
            SizedBox(width: 1.w),
            Text(
              'Accra, Ghana',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            CustomIconWidget(
              iconName: 'keyboard_arrow_down',
              color: theme.colorScheme.onSurface,
              size: 20,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'search',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: _navigateToSearch,
          ),
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                CustomIconWidget(
                  iconName: 'notifications_outlined',
                  color: theme.colorScheme.onSurface,
                  size: 24,
                ),
                // Unread badge
                unreadCountAsync.when(
                  data: (count) => count > 0
                      ? Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              count > 99 ? '99+' : count.toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications-screen');
            },
          ),
          SizedBox(width: 2.w),
        ],
      ),
      body: postsState.posts.isEmpty && postsState.isLoading
          ? const PostsShimmerList(itemCount: 5) // Beautiful shimmer loading
          : postsState.posts.isEmpty
          ? _buildEmptyState(theme)
          : RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: () => notifier.refreshPosts(),
              color: theme.colorScheme.primary,
              child: ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(bottom: 2.h),
                itemCount:
                    postsState.posts.length + (postsState.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == postsState.posts.length) {
                    return _buildLoadingIndicator(theme);
                  }

                  final post = postsState.posts[index];
                  return PostCardWidget(
                    post: post,
                    onLike: () => notifier.toggleLikeSafe(post.id),
                    onBookNow: () => _navigateToBooking(post),
                    onArtisanTap: () => _navigateToArtisanProfile(post),
                    onLongPress: () => _showPostOptions(post),
                    onSave: () async {
                      await ref
                          .read(postsNotifierProvider.notifier)
                          .toggleSave(post.id);
                      if (mounted) {
                        AppToast.show(
                          context,
                          message: post.isSaved
                              ? 'Post removed from saved'
                              : 'Post saved',
                          type: ToastType.success,
                        );
                      }
                    },
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: "posts_filter", // Add unique hero tag
        onPressed: _showFilterBottomSheet,
        backgroundColor: theme.colorScheme.primary,
        child: CustomIconWidget(
          iconName: 'tune',
          color: Colors.white,
          size: 24,
        ),
      ),
      bottomNavigationBar: const UnifiedBottomBar(currentIndex: 0),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'people_outline',
              color: theme.colorScheme.onSurfaceVariant,
              size: 80,
            ),
            SizedBox(height: 3.h),
            Text(
              'No Posts Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Follow artisans to see their posts and discover quality services in your area',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton(
              onPressed: _navigateToSearch,
              child: const Text('Discover Artisans'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child:
          const PostShimmerWidget(), // Use shimmer for pagination loading too
    );
  }
}
