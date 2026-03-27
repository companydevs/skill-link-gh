import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';
import 'package:skill_link_gh/data/repository/auth_repository.dart';
import 'package:skill_link_gh/provider/profile_provider.dart';
import 'package:skill_link_gh/widgets/custom_app_toast.dart';
import 'package:skill_link_gh/widgets/utils/createPost.dart';
import 'package:skill_link_gh/routes/app_routes.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/about_section_widget.dart';
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
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileState = ref.watch(profileNotifierProvider);

    // Skeleton on very first load
    if (profileState.isLoading && profileState.profileData == null) {
      return Scaffold(
        appBar: _buildAppBar(theme, null),
        bottomNavigationBar: CustomBottomBar(
          currentIndex: context.currentBottomBarIndex,
        ),
        body: _buildSkeleton(theme),
      );
    }

    if (profileState.error != null && profileState.profileData == null) {
      return Scaffold(
        appBar: _buildAppBar(theme, null),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              SizedBox(height: 2.h),
              Text(
                'Could not load profile',
                style: theme.textTheme.titleMedium,
              ),
              SizedBox(height: 2.h),
              ElevatedButton(
                onPressed: () =>
                    ref.read(profileNotifierProvider.notifier).refreshProfile(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final data = profileState.profileData!;
    final reviews = profileState.reviews;
    final portfolio = profileState.portfolioImages;
    final services = profileState.services;

    return Scaffold(
      appBar: _buildAppBar(theme, data),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: context.currentBottomBarIndex,
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'profile_create_post',
        mini: true,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreatePostScreen()),
        ),
        child: const Icon(Icons.post_add),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(child: ProfileHeaderWidget(artisanData: data)),
          SliverToBoxAdapter(child: ProfileStatsWidget(artisanData: data)),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: 1.5.h),
              child: VerificationStatusWidget(
                artisanData: data,
                onVerifyTap: () =>
                    Navigator.pushNamed(context, AppRoutes.verificationScreen),
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                indicatorColor: theme.colorScheme.primary,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: const [
                  Tab(text: 'About'),
                  Tab(text: 'Portfolio'),
                  Tab(text: 'Reviews'),
                  Tab(text: 'Services'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            AboutSectionWidget(artisanData: data),
            PortfolioSectionWidget(portfolioImages: portfolio),
            ReviewsSectionWidget(
              reviews: reviews,
              averageRating: (data['rating'] as num?)?.toDouble() ?? 0.0,
              totalReviews: reviews.length,
            ),
            ServicesSectionWidget(services: services),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    ThemeData theme,
    Map<String, dynamic>? data,
  ) {
    return AppBar(
      title: data != null
          ? Text(
              data['fullName'] as String? ?? '',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            )
          : null,
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.editProfileScreen),
        ),
        PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'logout') _handleLogout();
            if (v == 'delete') _handleDeleteAccount();
            if (v == 'verify')
              Navigator.pushNamed(context, AppRoutes.verificationScreen);
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'verify', child: Text('Get Verified')),
            const PopupMenuItem(value: 'logout', child: Text('Log out')),
            PopupMenuItem(
              value: 'delete',
              child: Text(
                'Delete Account',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSkeleton(ThemeData theme) {
    final c = theme.colorScheme.surfaceContainerHighest;
    Widget box(double w, double h, {double r = 8}) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(r),
      ),
    );
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              box(18.w, 18.w, r: 100),
              SizedBox(width: 4.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  box(35.w, 2.h),
                  SizedBox(height: 1.h),
                  box(22.w, 1.5.h),
                  SizedBox(height: 1.h),
                  box(28.w, 1.5.h),
                ],
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(3, (_) => box(20.w, 5.h, r: 8)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Log out'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: _isLoggingOut ? null : () => Navigator.pop(ctx, false),
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
                        if (mounted) Navigator.pop(ctx, true);
                      }
                    },
              child: _isLoggingOut
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Log out'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.loginScreen,
      (_) => false,
    );
  }

  Future<void> _handleDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This cannot be undone. All your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const PopScope(
          canPop: false,
          child: Dialog(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text('Deleting account...'),
                ],
              ),
            ),
          ),
        ),
      );
      await FirebaseFunctions.instance
          .httpsCallable('deleteUserAccount')
          .call();
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      Navigator.pushReplacementNamed(context, AppRoutes.loginScreen);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      AppToast.show(
        context,
        message: 'Failed to delete account. Please try again.',
        type: ToastType.error,
      );
    }
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarDelegate(this.tabBar);

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
  bool shouldRebuild(_TabBarDelegate old) => false;
}
