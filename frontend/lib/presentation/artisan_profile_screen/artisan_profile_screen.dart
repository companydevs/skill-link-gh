import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';
import 'package:skill_link_gh/data/repository/auth_repository.dart';
import 'package:skill_link_gh/provider/profile_provider.dart';
import 'package:skill_link_gh/notifier/profile_notifier.dart';
import 'package:skill_link_gh/presentation/in_app_messaging/in_app_messaging.dart';
import 'package:skill_link_gh/widgets/custom_app_toast.dart';
import 'package:skill_link_gh/widgets/utils/createPost.dart';
import 'package:skill_link_gh/routes/app_routes.dart';

import '../../core/app_export.dart';
import '../../data/repository/booking_repository.dart';
import '../../data/repository/post_repository.dart';
import '../../domain/models/booking_model.dart';
import '../../domain/models/post_model.dart';
import '../../domain/models/reel_model.dart';
import '../reels_screen/reels_screen.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../../widgets/unified_bottom_bar.dart';
import '../../widgets/user_avatar_widget.dart';
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

class _ArtisanProfileScreenState extends ConsumerState<ArtisanProfileScreen> {
  final AuthRepository _authRepository = AuthRepository();
  int _selectedTab = 0;
  bool _isLoggingOut = false;
  String _onlineStatus = 'offline'; // online, offline, busy
  bool _isTogglingStatus = false; // Track if we're currently toggling

  // For viewing another user's profile
  String? _viewingUserId;
  Map<String, dynamic>? _otherUserData;
  List<Map<String, dynamic>> _otherPortfolio = [];
  List<Map<String, dynamic>> _otherReviews = [];
  List<Map<String, dynamic>> _otherServices = [];
  bool _otherLoading = false;

  static const _tabs = [
    'About',
    'Portfolio',
    'Posts',
    'Reels',
    'Reviews',
    'Services',
    'Bookings',
    'Saved',
  ];

  // Tabs shown when viewing someone else (no Bookings/Saved)
  static const _otherTabs = ['About', 'Portfolio', 'Reviews', 'Services'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    print('🔍 [ARTISAN_PROFILE] didChangeDependencies called');

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    print('🔍 [ARTISAN_PROFILE] Raw arguments: $args');
    print('🔍 [ARTISAN_PROFILE] Arguments type: ${args.runtimeType}');

    final uid = args?['id'] as String?;
    print('🔍 [ARTISAN_PROFILE] Extracted uid: $uid');

    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    print('🔍 [ARTISAN_PROFILE] Current user ID: $currentUid');
    print(
      '🔍 [ARTISAN_PROFILE] Is viewing other user: ${uid != null && uid != currentUid}',
    );

    // Only load other user if it's a different person
    if (uid != null && uid != currentUid && uid != _viewingUserId) {
      print('✅ [ARTISAN_PROFILE] Loading other user profile: $uid');
      _viewingUserId = uid;
      _loadOtherUser(uid);
    } else if (uid == _viewingUserId) {
      print('⚠️ [ARTISAN_PROFILE] Already viewing this user: $uid');
    } else if (uid == currentUid) {
      print('ℹ️ [ARTISAN_PROFILE] Viewing own profile');
    } else {
      print('❌ [ARTISAN_PROFILE] No valid uid to load');
    }
  }

  Future<void> _loadOtherUser(String userId) async {
    print('🔍 [ARTISAN_PROFILE] _loadOtherUser started for: $userId');
    setState(() => _otherLoading = true);
    try {
      print('🔍 [ARTISAN_PROFILE] Fetching user document from Firestore...');
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      print('🔍 [ARTISAN_PROFILE] Document exists: ${doc.exists}');
      if (!doc.exists || !mounted) {
        print(
          '❌ [ARTISAN_PROFILE] Document does not exist or widget unmounted',
        );
        return;
      }

      final data = doc.data()!;
      data['id'] = userId;
      print(
        '✅ [ARTISAN_PROFILE] User data loaded: ${data['name']} (${data['trade']})',
      );

      // Resolve profile photo: profileImage → photoUrl → photoURL (Google sign-in field)
      final profileImage = data['profileImage'] as String? ?? '';
      if (profileImage.isEmpty) {
        final photoUrl = data['photoUrl'] as String? ?? '';
        final photoURL = data['photoURL'] as String? ?? '';
        final resolved = photoUrl.isNotEmpty ? photoUrl : photoURL;
        if (resolved.isNotEmpty) data['profileImage'] = resolved;
      }

      print(
        '🔍 [ARTISAN_PROFILE] Fetching portfolio, reviews, and services...',
      );
      final results = await Future.wait<List<Map<String, dynamic>>>([
        ref.read(profileRepositoryProvider).getPortfolioImages(userId),
        ref.read(profileRepositoryProvider).getReviews(userId),
        ref.read(profileRepositoryProvider).getServices(userId),
      ]);

      print('✅ [ARTISAN_PROFILE] Portfolio items: ${results[0].length}');
      print('✅ [ARTISAN_PROFILE] Reviews: ${results[1].length}');
      print('✅ [ARTISAN_PROFILE] Services: ${results[2].length}');

      if (mounted) {
        setState(() {
          _otherUserData = data;
          _otherPortfolio = results[0];
          _otherReviews = results[1];
          _otherServices = results[2];
          _otherLoading = false;
        });
        print('✅ [ARTISAN_PROFILE] Profile loaded successfully!');
      }
    } catch (e) {
      print('❌ [ARTISAN_PROFILE] Error loading user: $e');
      if (mounted) setState(() => _otherLoading = false);
    }
  }

  bool get _isViewingOther {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final uid = args?['id'] as String?;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    return uid != null && uid != currentUid;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ── Viewing someone else's profile ────────────────────────────────────
    if (_isViewingOther) {
      if (_otherLoading || _otherUserData == null) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: theme.colorScheme.surface,
            elevation: 0,
          ),
          body: _otherLoading
              ? _buildSkeleton(theme)
              : const Center(child: Text('Profile not found')),
        );
      }

      final data = _otherUserData!;
      return Scaffold(
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
          title: Text(
            data['fullName'] as String? ?? '',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.message_outlined),
              onPressed: () => Navigator.pushNamed(
                context,
                '/in-app-messaging-screen',
                arguments: ChatArgs(
                  otherUserId: data['id'] as String,
                  otherUserName: data['fullName'] as String? ?? '',
                  otherUserAvatar: data['profileImage'] as String? ?? '',
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: NestedScrollView(
                headerSliverBuilder: (ctx, _) => [
                  SliverToBoxAdapter(
                    child: ProfileHeaderWidget(artisanData: data),
                  ),
                  SliverToBoxAdapter(
                    child: ProfileStatsWidget(
                      artisanData: data,
                      jobsDone: 0,
                      bidsAccepted: 0,
                      postsCount: 0,
                    ),
                  ),
                  // ── Online Status Badge (Read-only for other users) ──
                  SliverToBoxAdapter(child: _buildOnlineStatusBadge(data)),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _PillTabBarDelegate(
                      tabs: _otherTabs,
                      selectedIndex: _selectedTab.clamp(
                        0,
                        _otherTabs.length - 1,
                      ),
                      onTap: (i) => setState(() => _selectedTab = i),
                      theme: theme,
                    ),
                  ),
                ],
                body: _buildOtherTabBody(data),
              ),
            ),
          ],
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton(
            onPressed: () => Navigator.pushNamed(
              context,
              '/service-booking-screen',
              arguments: data,
            ),
            child: const Text('Book Now'),
          ),
        ),
      );
    }

    // ── Own profile ───────────────────────────────────────────────────────
    final profileState = ref.watch(profileNotifierProvider);

    if (profileState.isLoading && profileState.profileData == null) {
      return Scaffold(
        appBar: _buildAppBar(theme, null),
        bottomNavigationBar: const UnifiedBottomBar(
          currentIndex: 4, // Profile tab
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
      bottomNavigationBar: const UnifiedBottomBar(
        currentIndex: 4, // Profile tab
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
      body: Column(
        children: [
          // ── Scrollable header ──────────────────────────────────────
          Expanded(
            child: NestedScrollView(
              headerSliverBuilder: (ctx, _) => [
                SliverToBoxAdapter(
                  child: ProfileHeaderWidget(artisanData: data),
                ),
                SliverToBoxAdapter(
                  child: ProfileStatsWidget(
                    artisanData: data,
                    jobsDone: profileState.jobsDone,
                    bidsAccepted: profileState.bidsAccepted,
                    postsCount: profileState.postsCount,
                  ),
                ),
                // ── Online Status Toggle ──────────────────────────────
                SliverToBoxAdapter(child: _buildOnlineStatusToggle(data)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 1.h),
                    child: VerificationStatusWidget(
                      artisanData: data,
                      onVerifyTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.verificationScreen,
                      ),
                    ),
                  ),
                ),
                // ── Pill tab selector ──────────────────────────────
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _PillTabBarDelegate(
                    tabs: _tabs,
                    selectedIndex: _selectedTab,
                    onTap: (i) => setState(() => _selectedTab = i),
                    theme: theme,
                  ),
                ),
              ],
              body: MediaQuery.removePadding(
                context: context,
                removeBottom: true,
                child: _buildTabBody(
                  selectedTab: _selectedTab,
                  data: data,
                  reviews: reviews,
                  portfolio: portfolio,
                  services: services,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherTabBody(Map<String, dynamic> data) {
    final tab = _selectedTab.clamp(0, _otherTabs.length - 1);
    switch (tab) {
      case 0:
        return AboutSectionWidget(artisanData: data);
      case 1:
        return PortfolioSectionWidget(portfolioImages: _otherPortfolio);
      case 2:
        return ReviewsSectionWidget(
          reviews: _otherReviews,
          averageRating: (data['rating'] as num?)?.toDouble() ?? 0.0,
          totalReviews: _otherReviews.length,
        );
      case 3:
        return ServicesSectionWidget(services: _otherServices);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTabBody({
    required int selectedTab,
    required Map<String, dynamic> data,
    required List<Map<String, dynamic>> reviews,
    required List<Map<String, dynamic>> portfolio,
    required List<Map<String, dynamic>> services,
  }) {
    switch (selectedTab) {
      case 0:
        return AboutSectionWidget(artisanData: data);
      case 1:
        return PortfolioSectionWidget(portfolioImages: portfolio);
      case 2:
        return _MyPostsTab(
          userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        );
      case 3:
        return _MyReelsTab(
          userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        );
      case 4:
        return ReviewsSectionWidget(
          reviews: reviews,
          averageRating: (data['rating'] as num?)?.toDouble() ?? 0.0,
          totalReviews: reviews.length,
        );
      case 5:
        return ServicesSectionWidget(services: services);
      case 6:
        return const _BookingsTab();
      case 7:
        return const _SavedPostsTab();
      default:
        return const SizedBox.shrink();
    }
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
          icon: const Icon(Icons.account_balance_wallet_outlined),
          tooltip: 'Wallet',
          onPressed: () => Navigator.pushNamed(context, AppRoutes.walletScreen),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.editProfileScreen),
        ),
        PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'logout') _handleLogout();
            if (v == 'delete') _handleDeleteAccount();
            if (v == 'verify') {
              Navigator.pushNamed(context, AppRoutes.verificationScreen);
            }
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
    return _ProfileShimmer(theme: theme);
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
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
                      setS(() => _isLoggingOut = true);
                      try {
                        await _authRepository.signOut();
                      } finally {
                        if (ctx.mounted) Navigator.pop(ctx, true);
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

  Widget _buildOnlineStatusToggle(Map<String, dynamic> data) {
    // Use local optimistic state during toggle, otherwise use stream data
    final currentStatus = _isTogglingStatus
        ? _onlineStatus
        : (data['onlineStatus'] as String? ?? _onlineStatus);
    final isOnline = currentStatus == 'online';
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isOnline
            ? const Color(0xFF10B981).withOpacity(0.05)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOnline
              ? const Color(0xFF10B981)
              : theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: isOnline
                  ? const Color(0xFF10B981).withOpacity(0.1)
                  : theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                isOnline ? Icons.check_circle : Icons.circle_outlined,
                color: isOnline
                    ? const Color(0xFF10B981)
                    : theme.colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOnline ? "You're Online" : "You're Offline",
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  isOnline
                      ? 'Accepting bookings and visible to clients'
                      : 'Not accepting immediate bookings',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 2.w),
          Switch(
            value: isOnline,
            onChanged: (value) => _toggleOnlineStatus(value),
            activeColor: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }

  // Read-only online status badge for viewing other users
  Widget _buildOnlineStatusBadge(Map<String, dynamic> data) {
    final currentStatus = data['onlineStatus'] as String? ?? 'offline';
    final isOnline = currentStatus == 'online';
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isOnline
            ? const Color(0xFF10B981).withOpacity(0.05)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOnline
              ? const Color(0xFF10B981)
              : theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: isOnline
                  ? const Color(0xFF10B981).withOpacity(0.1)
                  : theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                isOnline ? Icons.check_circle : Icons.circle_outlined,
                color: isOnline
                    ? const Color(0xFF10B981)
                    : theme.colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOnline ? "Available Now" : "Currently Offline",
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  isOnline
                      ? 'Accepting bookings and available for work'
                      : 'Not accepting immediate bookings',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleOnlineStatus(bool goOnline) async {
    final newStatus = goOnline ? 'online' : 'offline';

    // Update local state immediately for instant feedback
    setState(() {
      _onlineStatus = newStatus;
      _isTogglingStatus = true;
    });

    try {
      // Update in Firestore (in background)
      await ref.read(profileRepositoryProvider).updateOnlineStatus(newStatus);

      if (!mounted) return;

      // Clear toggling flag after successful update
      setState(() => _isTogglingStatus = false);

      AppToast.show(
        context,
        message: goOnline
            ? '✅ You are now online and accepting bookings'
            : '⚪ You are now offline',
        type: ToastType.success,
      );

      // Refresh profile to sync with backend
      ref.read(profileNotifierProvider.notifier).refreshProfile();
    } catch (e) {
      // Revert on error
      setState(() {
        _onlineStatus = goOnline ? 'offline' : 'online';
        _isTogglingStatus = false;
      });

      if (!mounted) return;
      AppToast.show(
        context,
        message: 'Failed to update status. Please try again.',
        type: ToastType.error,
      );
    }
  }
}

// ─── Profile shimmer ──────────────────────────────────────────────────────────
class _ProfileShimmer extends StatefulWidget {
  final ThemeData theme;
  const _ProfileShimmer({required this.theme});
  @override
  State<_ProfileShimmer> createState() => _ProfileShimmerState();
}

class _ProfileShimmerState extends State<_ProfileShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = Tween<double>(
      begin: -1.5,
      end: 2.5,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => _buildContent(),
    );
  }

  Widget _buildContent() {
    final base = widget.theme.colorScheme.surfaceContainerHighest;
    final highlight = widget.theme.colorScheme.surface;

    Widget shimBox(double w, double h, {double r = 8, bool full = false}) {
      return Container(
        width: full ? double.infinity : w,
        height: h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(r),
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value, 0),
            colors: [base, highlight, base],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover photo
          shimBox(double.infinity, 18.h, r: 0, full: true),

          // Avatar overlapping cover
          Transform.translate(
            offset: Offset(4.w, -24),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.theme.colorScheme.surface,
                  width: 3,
                ),
              ),
              child: shimBox(20.w, 20.w, r: 100),
            ),
          ),

          // Name + location + rating
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                shimBox(45.w, 2.4.h),
                SizedBox(height: 1.h),
                shimBox(28.w, 1.6.h),
                SizedBox(height: 0.8.h),
                shimBox(35.w, 1.6.h),
                SizedBox(height: 1.h),
                // Category chips
                Row(
                  children: [
                    shimBox(22.w, 3.h, r: 20),
                    SizedBox(width: 2.w),
                    shimBox(18.w, 3.h, r: 20),
                    SizedBox(width: 2.w),
                    shimBox(25.w, 3.h, r: 20),
                  ],
                ),
                SizedBox(height: 2.h),
              ],
            ),
          ),

          // Stats row — 3 cards
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              children: List.generate(
                3,
                (i) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 2 ? 2.w : 0),
                    child: shimBox(double.infinity, 10.h, r: 14, full: true),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 2.h),

          // Verification banner
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: shimBox(double.infinity, 7.h, r: 12, full: true),
          ),
          SizedBox(height: 2.h),

          // Tab pills
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              children: List.generate(
                4,
                (i) => Padding(
                  padding: EdgeInsets.only(right: 2.w),
                  child: shimBox(18.w, 4.h, r: 20),
                ),
              ),
            ),
          ),
          SizedBox(height: 2.h),

          // Content lines
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Column(
              children: List.generate(
                5,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: shimBox(
                    i % 2 == 0 ? double.infinity : 60.w,
                    1.8.h,
                    full: i % 2 == 0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pill tab bar ─────────────────────────────────────────────────────────────
class _PillTabBarDelegate extends SliverPersistentHeaderDelegate {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final ThemeData theme;

  const _PillTabBarDelegate({
    required this.tabs,
    required this.selectedIndex,
    required this.onTap,
    required this.theme,
  });

  @override
  double get minExtent => 56;
  @override
  double get maxExtent => 56;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final selected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
              decoration: BoxDecoration(
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tabs[i],
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  bool shouldRebuild(_PillTabBarDelegate old) =>
      old.selectedIndex != selectedIndex;
}

// ─── Bookings tab ─────────────────────────────────────────────────────────────
class _BookingsTab extends StatefulWidget {
  const _BookingsTab();
  @override
  State<_BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<_BookingsTab>
    with AutomaticKeepAliveClientMixin {
  final _repo = BookingRepository();
  List<BookingModel> _bookings = [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final b = await _repo.getUserBookings(userType: 'client');
      if (mounted) {
        setState(() {
          _bookings = b;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'No bookings yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your booking history will appear here',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _bookings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _BookingCard(booking: _bookings[i]),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  const _BookingCard({required this.booking});

  Color _statusColor(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    switch (booking.status) {
      case BookingStatus.confirmed:
        return c.primary;
      case BookingStatus.inProgress:
        return Colors.orange;
      case BookingStatus.completed:
        return Colors.green;
      case BookingStatus.cancelled:
      case BookingStatus.paymentFailed:
        return c.error;
      default:
        return c.onSurfaceVariant;
    }
  }

  String _statusLabel() {
    switch (booking.status) {
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.paymentPending:
        return 'Payment Pending';
      case BookingStatus.paymentFailed:
        return 'Payment Failed';
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(context);
    final canTrack =
        booking.status == BookingStatus.confirmed ||
        booking.status == BookingStatus.inProgress;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/booking-tracking-screen',
        arguments: {'bookingId': booking.id},
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.serviceTitle.isNotEmpty
                        ? booking.serviceTitle
                        : 'Service Booking',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  booking.scheduledDate,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.access_time_outlined,
                  size: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  booking.scheduledTime,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  'GH₵ ${booking.totalWithFees.toStringAsFixed(2)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  canTrack ? Icons.location_on : Icons.open_in_new,
                  size: 13,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  canTrack ? 'Tap to track' : 'Tap to view details',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Saved Posts tab ──────────────────────────────────────────────────────────
class _SavedPostsTab extends StatefulWidget {
  const _SavedPostsTab();
  @override
  State<_SavedPostsTab> createState() => _SavedPostsTabState();
}

class _SavedPostsTabState extends State<_SavedPostsTab>
    with AutomaticKeepAliveClientMixin {
  final _repo = PostRepository();
  List<PostModel> _savedPosts = [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final ids = await _repo.fetchSavedPostIds();
      if (ids.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      // Fetch full post data for each saved post
      final posts = <PostModel>[];
      for (final id in ids) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('posts')
              .doc(id)
              .get();
          if (doc.exists) {
            posts.add(PostModel.fromFirestore(doc));
          }
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _savedPosts = posts;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showPostDetail(BuildContext context, PostModel post, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _SavedPostDetailSheet(posts: _savedPosts, initialIndex: index),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_savedPosts.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bookmark_border,
                size: 56,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.4,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'No saved posts yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Posts you save will appear here',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: GridView.builder(
        padding: const EdgeInsets.all(2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
          childAspectRatio: 1,
        ),
        itemCount: _savedPosts.length,
        itemBuilder: (context, i) {
          final post = _savedPosts[i];
          return GestureDetector(
            onTap: () => _showPostDetail(context, post, i),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomImageWidget(
                  imageUrl: post.postImages.isNotEmpty
                      ? post.postImages[0].url
                      : kDefaultMaleAvatar,
                  fit: BoxFit.cover,
                  semanticLabel: post.description,
                ),
                if (post.postImages.length > 1)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.collections,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── My Posts Tab ─────────────────────────────────────────────────────────────
class _MyPostsTab extends StatefulWidget {
  final String userId;
  const _MyPostsTab({required this.userId});

  @override
  State<_MyPostsTab> createState() => _MyPostsTabState();
}

class _MyPostsTabState extends State<_MyPostsTab>
    with AutomaticKeepAliveClientMixin {
  List<QueryDocumentSnapshot> _posts = [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // No orderBy — avoids depending on a composite index existing for
      // artisanId + createdAt; sort client-side instead.
      final snap = await FirebaseFirestore.instance
          .collection('posts')
          .where('artisanId', isEqualTo: widget.userId)
          .get();
      final docs = List<QueryDocumentSnapshot>.from(snap.docs)
        ..sort((a, b) {
          final aTime =
              (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          final bTime =
              (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });
      if (mounted)
        setState(() {
          _posts = docs;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deletePost(String postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text(
          'Are you sure you want to delete this post? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_posts.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 56,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.4,
                ),
              ),
              const SizedBox(height: 12),
              Text('No posts yet', style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                'Your posts will appear here',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: GridView.builder(
        padding: const EdgeInsets.all(2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
          childAspectRatio: 1,
        ),
        itemCount: _posts.length,
        itemBuilder: (context, i) {
          final data = _posts[i].data() as Map<String, dynamic>;
          final images = data['postImages'] as List? ?? [];
          final imageUrl = images.isNotEmpty
              ? (images[0] as Map<String, dynamic>)['url'] as String? ?? ''
              : '';
          return GestureDetector(
            onTap: () {
              final postModels = _posts
                  .map((doc) => PostModel.fromFirestore(doc))
                  .toList();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _MyPostDetailSheet(
                  posts: postModels,
                  initialIndex: i,
                  onDelete: () => _deletePost(_posts[i].id),
                ),
              );
            },
            onLongPress: () => _deletePost(_posts[i].id),
            child: Stack(
              fit: StackFit.expand,
              children: [
                imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                        ),
                      )
                    : Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.image_outlined),
                      ),
                // Multiple images indicator
                if (images.length > 1)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.collections,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── My Reels Tab ─────────────────────────────────────────────────────────────
class _MyReelsTab extends StatefulWidget {
  final String userId;
  const _MyReelsTab({required this.userId});

  @override
  State<_MyReelsTab> createState() => _MyReelsTabState();
}

class _MyReelsTabState extends State<_MyReelsTab>
    with AutomaticKeepAliveClientMixin {
  List<QueryDocumentSnapshot> _reels = [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // No orderBy — avoids depending on a composite index existing for
      // artisanId + createdAt; sort client-side instead.
      final snap = await FirebaseFirestore.instance
          .collection('reels')
          .where('artisanId', isEqualTo: widget.userId)
          .get();
      final docs = List<QueryDocumentSnapshot>.from(snap.docs)
        ..sort((a, b) {
          final aTime =
              (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          final bTime =
              (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });
      if (mounted)
        setState(() {
          _reels = docs;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteReel(String reelId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Reel'),
        content: const Text(
          'Are you sure you want to delete this reel? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await FirebaseFirestore.instance.collection('reels').doc(reelId).delete();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_reels.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.play_circle_outline,
                size: 56,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.4,
                ),
              ),
              const SizedBox(height: 12),
              Text('No reels yet', style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                'Your reels will appear here',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: GridView.builder(
        padding: const EdgeInsets.all(2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
          childAspectRatio: 9 / 16,
        ),
        itemCount: _reels.length,
        itemBuilder: (context, i) {
          final data = _reels[i].data() as Map<String, dynamic>;
          final thumbnail = data['thumbnailUrl'] as String? ?? '';
          final videoUrl = data['videoUrl'] as String? ?? '';
          return GestureDetector(
            onTap: () {
              final reelsList = _reels
                  .map((doc) => Reel.fromFirestore(doc))
                  .toList();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ReelsScreen(initialReels: reelsList, initialIndex: i),
                ),
              );
            },
            onLongPress: () => _deleteReel(_reels[i].id),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ReelThumbnailWidget(
                  thumbnailUrl: thumbnail,
                  videoUrl: videoUrl,
                ),
                // Play icon overlay
                const Center(
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white70,
                    size: 28,
                  ),
                ),
                // Delete hint
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ReelThumbnailWidget extends StatefulWidget {
  final String? thumbnailUrl;
  final String videoUrl;

  const ReelThumbnailWidget({
    super.key,
    required this.thumbnailUrl,
    required this.videoUrl,
  });

  @override
  State<ReelThumbnailWidget> createState() => _ReelThumbnailWidgetState();
}

class _ReelThumbnailWidgetState extends State<ReelThumbnailWidget> {
  Uint8List? _frameBytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.thumbnailUrl == null || widget.thumbnailUrl!.isEmpty) {
      _generateThumbnail();
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _generateThumbnail() async {
    try {
      final bytes = await VideoThumbnail.thumbnailData(
        video: widget.videoUrl,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 400,
        quality: 75,
        timeMs: 1000, // grab frame at 1 second — avoids black first frame
      );
      if (mounted) {
        setState(() {
          _frameBytes = bytes;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Thumbnail generation error: $e');
      if (mounted)
        setState(() {
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Has stored thumbnail URL — use it directly
    if (widget.thumbnailUrl != null && widget.thumbnailUrl!.isNotEmpty) {
      return Image.network(
        widget.thumbnailUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : _buildSpinner(),
        errorBuilder: (_, __, ___) => _buildBlack(),
      );
    }

    // Still generating
    if (_loading) return _buildSpinner();

    // Generated frame bytes available
    if (_frameBytes != null) {
      return Image.memory(
        _frameBytes!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildBlack(),
      );
    }

    // Error fallback
    return _buildBlack();
  }

  Widget _buildSpinner() => Container(
    color: const Color(0xFF1C1C1E),
    child: const Center(
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38),
      ),
    ),
  );

  Widget _buildBlack() => Container(
    color: const Color(0xFF1C1C1E),
    child: const Icon(
      Icons.play_circle_outline,
      color: Colors.white38,
      size: 32,
    ),
  );
}

// ─── My Post Detail Sheet ─────────────────────────────────────────────────────
class _MyPostDetailSheet extends StatefulWidget {
  final List<PostModel> posts;
  final int initialIndex;
  final VoidCallback onDelete;

  const _MyPostDetailSheet({
    required this.posts,
    required this.initialIndex,
    required this.onDelete,
  });

  @override
  State<_MyPostDetailSheet> createState() => _MyPostDetailSheetState();
}

class _MyPostDetailSheetState extends State<_MyPostDetailSheet> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final h = MediaQuery.of(context).size.height;

    return Container(
      height: h * 0.92,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // page counter + delete button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_currentIndex + 1} / ${widget.posts.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.error,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onDelete();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.posts.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (_, i) => _PostDetailCard(post: widget.posts[i]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Saved Post Detail Sheet ──────────────────────────────────────────────────
class _SavedPostDetailSheet extends StatefulWidget {
  final List<PostModel> posts;
  final int initialIndex;

  const _SavedPostDetailSheet({
    required this.posts,
    required this.initialIndex,
  });

  @override
  State<_SavedPostDetailSheet> createState() => _SavedPostDetailSheetState();
}

class _SavedPostDetailSheetState extends State<_SavedPostDetailSheet> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final h = MediaQuery.of(context).size.height;

    return Container(
      height: h * 0.92,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // page counter
          Text(
            '${_currentIndex + 1} / ${widget.posts.length}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.posts.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (_, i) => _PostDetailCard(post: widget.posts[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostDetailCard extends StatelessWidget {
  final PostModel post;
  const _PostDetailCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header — tap avatar/name to go to their profile ──────────────
          GestureDetector(
            onTap: () {
              Navigator.pop(context); // close sheet first
              Navigator.pushNamed(context, AppRoutes.artisanProfile);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: ClipOval(
                      child: CustomImageWidget(
                        imageUrl: post.artisanImage.isNotEmpty
                            ? post.artisanImage
                            : kDefaultMaleAvatar,
                        width: 38,
                        height: 38,
                        fit: BoxFit.cover,
                        semanticLabel: post.artisanName,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.artisanName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          post.serviceCategory,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // View profile chip
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.artisanProfile);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.primary),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'View profile',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Images ────────────────────────────────────────────────────────
          if (post.postImages.isNotEmpty)
            post.postImages.length > 1
                ? SizedBox(
                    height: MediaQuery.of(context).size.width,
                    child: PageView(
                      children: post.postImages
                          .map(
                            (img) => CustomImageWidget(
                              imageUrl: img.url,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              semanticLabel: img.label,
                            ),
                          )
                          .toList(),
                    ),
                  )
                : CustomImageWidget(
                    imageUrl: post.postImages[0].url,
                    width: double.infinity,
                    height: MediaQuery.of(context).size.width,
                    fit: BoxFit.cover,
                    semanticLabel: post.postImages[0].label,
                  ),

          // ── Caption ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: '${post.artisanName}  ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: post.description),
                ],
              ),
            ),
          ),

          // ── Pricing + Book Now ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    post.pricing,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                      context,
                      AppRoutes.serviceBooking,
                      arguments: {'artisanId': post.artisanId},
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Book Now'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
