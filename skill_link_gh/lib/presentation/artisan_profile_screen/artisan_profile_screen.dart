import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';
import 'package:skill_link_gh/data/repository/auth_repository.dart';
import 'package:skill_link_gh/provider/profile_provider.dart';
import 'package:skill_link_gh/widgets/user_avatar_widget.dart';
import 'package:skill_link_gh/widgets/custom_app_toast.dart';
import 'package:skill_link_gh/widgets/utils/createPost.dart';
import 'package:skill_link_gh/routes/app_routes.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/about_section_widget.dart';
import './widgets/action_buttons_widget.dart';
import './widgets/portfolio_section_widget.dart';
import './widgets/profile_header_widget.dart';
import './widgets/profile_stats_widget.dart';
import './widgets/reviews_section_widget.dart';
import './widgets/services_section_widget.dart';
import './widgets/verification_status_widget.dart';

class ArtisanProfileScreen extends ConsumerStatefulWidget {
  const ArtisanProfileScreen({super.key});

  @override
  ConsumerState<ArtisanProfileScreen> createState() =>
      _ArtisanProfileScreenState();
}

class _ArtisanProfileScreenState extends ConsumerState<ArtisanProfileScreen>
    with SingleTickerProviderStateMixin {
  final AuthRepository _authRepository = AuthRepository();

  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _showStickyHeader = false;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.offset > 200 && !_showStickyHeader) {
      setState(() => _showStickyHeader = true);
    } else if (_scrollController.offset <= 200 && _showStickyHeader) {
      setState(() => _showStickyHeader = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleBookNow() {
    Navigator.pushNamed(context, '/service-booking-screen');
  }

  void _handleMessage() {
    Navigator.pushNamed(context, '/posts-homepage');
  }

  void _handleShare() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile sharing coming soon')),
    );
  }

  void _handleFavorite() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Added to favorites')));
  }

  void _handleReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report User'),
        content: const Text('Are you sure you want to report this artisan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Report submitted')));
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  void _handleVerification() {
    Navigator.pushNamed(context, AppRoutes.verificationScreen);
  }

  bool _isVerified(Map<String, dynamic> artisanData) {
    final verificationBadges =
        artisanData["verificationBadges"] as Map<String, dynamic>?;
    return verificationBadges?["identityVerified"] == true;
  }

  // Create Post Handler
  void _handleCreatePost() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileState = ref.watch(profileNotifierProvider);

    // Show full-screen loader only on first ever load (no cached data yet)
    if (profileState.isLoading && profileState.profileData == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CustomAppBar(variant: AppBarVariant.transparent),
        bottomNavigationBar: CustomBottomBar(
          currentIndex: context.currentBottomBarIndex,
        ),
        body: _buildProfileSkeleton(theme),
      );
    }

    // If we have an error and no data at all, show error state
    if (profileState.error != null && profileState.profileData == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text('Failed to load profile', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                profileState.error!,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(profileNotifierProvider.notifier).refreshProfile();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final artisanData = profileState.profileData!;
    final portfolioImages = profileState.portfolioImages;
    final reviews = profileState.reviews;
    final services = profileState.services;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: _showStickyHeader
          ? CustomAppBar(
              variant: AppBarVariant.standard,
              backgroundColor: theme.colorScheme.surface,
              titleWidget: Row(
                children: [
                  UserAvatarWidget(
                    imageUrl: artisanData["profileImage"] as String?,
                    name: artisanData["fullName"] as String? ?? 'Unknown User',
                    size: 40,
                    semanticLabel: 'Profile picture',
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          artisanData["fullName"] as String? ?? 'Unknown User',
                          style: theme.textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'star',
                              size: 14,
                              color: theme.colorScheme.secondary,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              '${artisanData["rating"] ?? 0.0} (${reviews.length})',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: CustomIconWidget(
                    iconName: 'edit',
                    size: 24,
                    color: theme.colorScheme.onSurface,
                  ),
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.editProfileScreen),
                ),
                IconButton(
                  icon: CustomIconWidget(
                    iconName: 'share',
                    size: 24,
                    color: theme.colorScheme.onSurface,
                  ),
                  onPressed: _handleShare,
                ),
                PopupMenuButton<String>(
                  icon: CustomIconWidget(
                    iconName: 'more_vert',
                    size: 24,
                    color: Colors.white,
                  ),
                  onSelected: (value) {
                    if (value == 'favorite') _handleFavorite();
                    if (value == 'report') _handleReport();
                    if (value == 'logout') _handleLogout();
                    if (value == 'delete') _handleDeleteAccount();
                    if (value == 'verify') _handleVerification();
                  },
                  itemBuilder: (context) => [
                    if (!_isVerified(artisanData))
                      const PopupMenuItem(
                        value: 'verify',
                        child: Row(
                          children: [
                            Icon(Icons.verified_user, size: 20),
                            SizedBox(width: 8),
                            Text('Get Verified'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'favorite',
                      child: Text('Save to Favorites'),
                    ),
                    const PopupMenuItem(
                      value: 'report',
                      child: Text('Report User'),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Text('Log out'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete Account',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : CustomAppBar(
              variant: AppBarVariant.transparent,
              actions: [
                IconButton(
                  icon: CustomIconWidget(
                    iconName: 'edit',
                    size: 24,
                    color: Colors.white,
                  ),
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.editProfileScreen),
                ),
                IconButton(
                  icon: CustomIconWidget(
                    iconName: 'share',
                    size: 24,
                    color: Colors.white,
                  ),
                  onPressed: _handleShare,
                ),
                PopupMenuButton<String>(
                  icon: CustomIconWidget(
                    iconName: 'more_vert',
                    size: 24,
                    color: Colors.white,
                  ),
                  onSelected: (value) {
                    if (value == 'favorite') _handleFavorite();
                    if (value == 'report') _handleReport();
                    if (value == 'logout') _handleLogout();
                    if (value == 'delete') _handleDeleteAccount();
                    if (value == 'verify') _handleVerification();
                  },
                  itemBuilder: (context) => [
                    if (!_isVerified(artisanData))
                      const PopupMenuItem(
                        value: 'verify',
                        child: Row(
                          children: [
                            Icon(Icons.verified_user, size: 20),
                            SizedBox(width: 8),
                            Text('Get Verified'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'favorite',
                      child: Text('Save to Favorites'),
                    ),
                    const PopupMenuItem(
                      value: 'report',
                      child: Text('Report User'),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Text('Log out'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete Account',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: ProfileHeaderWidget(artisanData: artisanData),
              ),
              SliverToBoxAdapter(
                child: ProfileStatsWidget(artisanData: artisanData),
              ),
              // Add verification status widget if not fully verified
              SliverToBoxAdapter(
                child: VerificationStatusWidget(
                  artisanData: artisanData,
                  onVerifyTap: _handleVerification,
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                    indicatorColor: theme.colorScheme.primary,
                    tabs: const [
                      Tab(text: 'About'),
                      Tab(text: 'Portfolio'),
                      Tab(text: 'Reviews'),
                      Tab(text: 'Services'),
                    ],
                  ),
                ),
              ),
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    AboutSectionWidget(artisanData: artisanData),
                    PortfolioSectionWidget(portfolioImages: portfolioImages),
                    ReviewsSectionWidget(
                      reviews: reviews,
                      averageRating:
                          (artisanData["rating"] as num?)?.toDouble() ?? 0.0,
                      totalReviews: reviews.length,
                    ),
                    ServicesSectionWidget(services: services),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ActionButtonsWidget(
              onBookNow: _handleBookNow,
              onMessage: _handleMessage,
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: context.currentBottomBarIndex,
      ),
      // FAB for creating post
      floatingActionButton: FloatingActionButton(
        heroTag: "profile_create_post", // Add unique hero tag
        onPressed: _handleCreatePost,
        child: const Icon(Icons.post_add),
      ),
    );
  }

  Widget _buildProfileSkeleton(ThemeData theme) {
    final shimmerBase = theme.colorScheme.surfaceContainerHighest;
    final shimmerHighlight = theme.colorScheme.surface;

    Widget box(double w, double h, {double radius = 8}) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: shimmerBase,
        borderRadius: BorderRadius.circular(radius),
      ),
    );

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover photo placeholder
          Container(height: 22.h, color: shimmerBase),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 20.w,
                      height: 20.w,
                      decoration: BoxDecoration(
                        color: shimmerHighlight,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.surface,
                          width: 3,
                        ),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        box(40.w, 2.h),
                        SizedBox(height: 1.h),
                        box(25.w, 1.5.h),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                box(double.infinity, 1.5.h),
                SizedBox(height: 1.h),
                box(60.w, 1.5.h),
                SizedBox(height: 3.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(3, (_) => box(20.w, 6.h, radius: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Log out'),
            content: const Text('Are you sure you want to log out?'),
            actions: [
              TextButton(
                onPressed: _isLoggingOut
                    ? null
                    : () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _isLoggingOut
                    ? null
                    : () async {
                        setState(() => _isLoggingOut = true);
                        try {
                          await _authRepository.signOut();
                        } finally {
                          if (mounted) Navigator.pop(context, true);
                        }
                      },
                child: _isLoggingOut
                    ? const CircularProgressIndicator()
                    : const Text('Log out'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.loginScreen,
      (route) => false,
    );
  }

  Future<void> _handleDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      showLoadingDialog(context, message: 'Deleting your account...');
      final functions = FirebaseFunctions.instance;
      await functions.httpsCallable('deleteUserAccount').call();
      await FirebaseAuth.instance.signOut();
      Navigator.of(context, rootNavigator: true).pop();
      Navigator.pushReplacementNamed(context, '/login-screen');
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      AppToast.show(
        context,
        message: 'Failed to delete account. Please try again.',
        type: ToastType.error,
      );
    }
  }

  void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 20),
                Text(message ?? 'Please wait...'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}
