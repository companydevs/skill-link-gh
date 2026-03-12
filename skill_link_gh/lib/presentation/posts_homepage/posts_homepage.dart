import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';
import 'package:skill_link_gh/domain/models/post_model.dart';
import 'package:skill_link_gh/presentation/posts_homepage/widgets/filter_bottom_sheet_widget.dart';
import 'package:skill_link_gh/provider/post_provider.dart';
import 'package:skill_link_gh/widgets/post_shimmer_widget.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';
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
      builder: (context) {
        final theme = Theme.of(context);
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
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: CustomIconWidget(
                    iconName: 'bookmark_border',
                    color: theme.colorScheme.onSurface,
                    size: 24,
                  ),
                  title: Text('Save Post', style: theme.textTheme.bodyLarge),
                  onTap: () {
                    Navigator.pop(context);
                    ref
                        .read(postsNotifierProvider.notifier)
                        .toggleSave(post.id);
                  },
                ),
                ListTile(
                  leading: CustomIconWidget(
                    iconName: 'share',
                    color: theme.colorScheme.onSurface,
                    size: 24,
                  ),
                  title: Text('Share', style: theme.textTheme.bodyLarge),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: CustomIconWidget(
                    iconName: 'report',
                    color: theme.colorScheme.error,
                    size: 24,
                  ),
                  title: Text(
                    'Report',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  onTap: () => Navigator.pop(context),
                ),
                SizedBox(height: 2.h),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final postsState = ref.watch(postsNotifierProvider);
    final notifier = ref.watch(postsNotifierProvider.notifier);

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
            icon: CustomIconWidget(
              iconName: 'notifications_outlined',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: () {},
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
                    // onComment: () => _navigateToPostDetail(post),
                    onBookNow: () => _navigateToBooking(post),
                    onArtisanTap: () => _navigateToArtisanProfile(post),
                    // onPostTap: () => _navigateToPostDetail(post),
                    onLongPress: () => _showPostOptions(post),
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
      bottomNavigationBar: const CustomBottomBar(currentIndex: 0),
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
