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
import '../../data/repository/booking_repository.dart';
import '../../domain/models/booking_model.dart';
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

class _ArtisanProfileScreenState extends ConsumerState<ArtisanProfileScreen> {
  final AuthRepository _authRepository = AuthRepository();
  int _selectedTab = 0;
  bool _isLoggingOut = false;

  static const _tabs = [
    'About',
    'Portfolio',
    'Reviews',
    'Services',
    'Bookings',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileState = ref.watch(profileNotifierProvider);

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
                SliverToBoxAdapter(
                  child: VerificationStatusWidget(
                    artisanData: data,
                    onVerifyTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.verificationScreen,
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
              body: _buildTabBody(
                selectedTab: _selectedTab,
                data: data,
                reviews: reviews,
                portfolio: portfolio,
                services: services,
              ),
            ),
          ),
        ],
      ),
    );
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
        return ReviewsSectionWidget(
          reviews: reviews,
          averageRating: (data['rating'] as num?)?.toDouble() ?? 0.0,
          totalReviews: reviews.length,
        );
      case 3:
        return ServicesSectionWidget(services: services);
      case 4:
        return const _BookingsTab();
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
            children: List.generate(3, (_) => box(25.w, 8.h, r: 14)),
          ),
        ],
      ),
    );
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
      onTap: canTrack
          ? () => Navigator.pushNamed(
              context,
              '/booking-tracking-screen',
              arguments: {'bookingId': booking.id},
            )
          : null,
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
            if (canTrack) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.location_on,
                    size: 13,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tap to track',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
