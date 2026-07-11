import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../domain/models/booking_model.dart';
import '../../provider/booking_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/unified_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import '../in_app_messaging/in_app_messaging.dart';
import './widgets/booking_filter_sheet.dart';
import './widgets/empty_state_widget.dart';

class BookingManagement extends ConsumerStatefulWidget {
  const BookingManagement({super.key});

  @override
  ConsumerState<BookingManagement> createState() => _BookingManagementState();
}

class _BookingManagementState extends ConsumerState<BookingManagement> {
  String _selectedStatus = 'Upcoming';
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  final List<String> _statusOptions = ['Upcoming', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    // Load real bookings from Firestore on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingNotifierProvider.notifier).loadUserBookings('client');
    });
  }

  List<BookingModel> _getFilteredBookings(List<BookingModel> all) {
    return all.where((b) {
      // Status filter
      bool statusMatch = false;
      if (_selectedStatus == 'Upcoming') {
        statusMatch =
            b.status == BookingStatus.pending ||
            b.status == BookingStatus.confirmed ||
            b.status == BookingStatus.inProgress ||
            b.status == BookingStatus.paymentPending;
      } else if (_selectedStatus == 'Completed') {
        statusMatch = b.status == BookingStatus.completed;
      } else if (_selectedStatus == 'Cancelled') {
        statusMatch =
            b.status == BookingStatus.cancelled ||
            b.status == BookingStatus.paymentFailed;
      }

      // Date filter
      bool dateMatch = true;
      if (_filterStartDate != null && _filterEndDate != null) {
        final bookingDate = DateTime.tryParse(b.scheduledDate) ?? b.createdAt;
        dateMatch =
            bookingDate.isAfter(
              _filterStartDate!.subtract(const Duration(days: 1)),
            ) &&
            bookingDate.isBefore(_filterEndDate!.add(const Duration(days: 1)));
      }

      return statusMatch && dateMatch;
    }).toList()..sort((a, b) {
      final dateA = DateTime.tryParse(a.scheduledDate) ?? a.createdAt;
      final dateB = DateTime.tryParse(b.scheduledDate) ?? b.createdAt;
      return _selectedStatus == 'Upcoming'
          ? dateA.compareTo(dateB)
          : dateB.compareTo(dateA);
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookingFilterSheet(
        startDate: _filterStartDate,
        endDate: _filterEndDate,
        onApply: (start, end) {
          setState(() {
            _filterStartDate = start;
            _filterEndDate = end;
          });
        },
      ),
    );
  }

  void _handleMessage(BookingModel booking) {
    // Navigate to real chat with the artisan
    Navigator.pushNamed(
      context,
      AppRoutes.inAppMessagingScreen,
      arguments: ChatArgs(
        otherUserId: booking.artisanId,
        otherUserName: booking.serviceTitle,
        otherUserAvatar: '',
      ),
    );
  }

  void _handleCancel(BookingModel booking) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text(
          'Are you sure you want to cancel this booking? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(bookingNotifierProvider.notifier)
                  .updateBookingStatus(
                    bookingId: booking.id,
                    status: BookingStatus.cancelled,
                  );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Booking cancelled')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _handleViewTracking(BookingModel booking) {
    Navigator.pushNamed(
      context,
      AppRoutes.bookingTrackingScreen,
      arguments: {'bookingId': booking.id},
    );
  }

  String _statusLabel(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
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
    }
  }

  Color _statusColor(BookingStatus status, ThemeData theme) {
    switch (status) {
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.inProgress:
        return Colors.blue;
      case BookingStatus.completed:
        return Colors.teal;
      case BookingStatus.cancelled:
      case BookingStatus.paymentFailed:
        return theme.colorScheme.error;
      case BookingStatus.paymentPending:
      case BookingStatus.pending:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bookingState = ref.watch(bookingNotifierProvider);
    final filtered = _getFilteredBookings(bookingState.bookings);

    return Scaffold(
      appBar: CustomAppBar(
        variant: AppBarVariant.standard,
        title: 'Bookings',
        actions: [
          IconButton(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.notificationsScreen),
            icon: CustomIconWidget(
              iconName: 'notifications_outlined',
              color: theme.colorScheme.onSurface,
              size: 6.w,
            ),
          ),
          IconButton(
            onPressed: _showFilterSheet,
            icon: CustomIconWidget(
              iconName: 'filter_list',
              color: theme.colorScheme.onSurface,
              size: 6.w,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status tabs
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: _statusOptions.map((status) {
                  final isSelected = _selectedStatus == status;
                  return Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedStatus = status),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          status,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Active date filter chip
          if (_filterStartDate != null && _filterEndDate != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    color: theme.colorScheme.primary,
                    size: 16,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      '${_filterStartDate!.day}/${_filterStartDate!.month}/${_filterStartDate!.year} - ${_filterEndDate!.day}/${_filterEndDate!.month}/${_filterEndDate!.year}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() {
                      _filterStartDate = null;
                      _filterEndDate = null;
                    }),
                    icon: Icon(
                      Icons.close,
                      color: theme.colorScheme.primary,
                      size: 16,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

          SizedBox(height: 1.h),

          // Content
          Expanded(
            child: bookingState.isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                  )
                : bookingState.error != null
                ? _buildError(theme, bookingState.error!)
                : filtered.isEmpty
                ? EmptyStateWidget(
                    title: _selectedStatus == 'Upcoming'
                        ? 'No Upcoming Bookings'
                        : _selectedStatus == 'Completed'
                        ? 'No Completed Bookings'
                        : 'No Cancelled Bookings',
                    message: _selectedStatus == 'Upcoming'
                        ? 'You don\'t have any upcoming appointments. Book a service to get started!'
                        : _selectedStatus == 'Completed'
                        ? 'You haven\'t completed any bookings yet.'
                        : 'You don\'t have any cancelled bookings.',
                    buttonText: _selectedStatus == 'Upcoming'
                        ? 'Book a Service'
                        : 'Browse Services',
                    onButtonPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.searchAndDiscovery,
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => ref
                        .read(bookingNotifierProvider.notifier)
                        .loadUserBookings('client'),
                    child: ListView.separated(
                      padding: EdgeInsets.only(
                        left: 4.w,
                        right: 4.w,
                        bottom: 2.h,
                      ),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => SizedBox(height: 1.5.h),
                      itemBuilder: (context, index) {
                        final booking = filtered[index];
                        return _BookingCard(
                          booking: booking,
                          statusLabel: _statusLabel(booking.status),
                          statusColor: _statusColor(booking.status, theme),
                          onMessage: () => _handleMessage(booking),
                          onTrack: () => _handleViewTracking(booking),
                          onCancel: _selectedStatus == 'Upcoming'
                              ? () => _handleCancel(booking)
                              : null,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'booking_create',
        onPressed: () =>
            Navigator.pushNamed(context, AppRoutes.searchAndDiscovery),
        icon: CustomIconWidget(
          iconName: 'add',
          color: theme.colorScheme.onPrimary,
          size: 6.w,
        ),
        label: const Text('New Booking'),
      ),
      bottomNavigationBar: const UnifiedBottomBar(currentIndex: 4),
    );
  }

  Widget _buildError(ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            SizedBox(height: 2.h),
            Text('Failed to load bookings', style: theme.textTheme.titleMedium),
            SizedBox(height: 1.h),
            Text(
              error,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            ElevatedButton.icon(
              onPressed: () => ref
                  .read(bookingNotifierProvider.notifier)
                  .loadUserBookings('client'),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Real booking card ─────────────────────────────────────────────────────────
class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final String statusLabel;
  final Color statusColor;
  final VoidCallback onMessage;
  final VoidCallback onTrack;
  final VoidCallback? onCancel;

  const _BookingCard({
    required this.booking,
    required this.statusLabel,
    required this.statusColor,
    required this.onMessage,
    required this.onTrack,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.build_outlined,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.serviceTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Ref: ${booking.bookingReference}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 1.5.h),
            Divider(
              height: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.15),
            ),
            SizedBox(height: 1.5.h),

            // Date & time
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: 1.w),
                Text(
                  booking.scheduledDate,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(width: 4.w),
                Icon(
                  Icons.access_time_outlined,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: 1.w),
                Text(
                  booking.scheduledTime,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            SizedBox(height: 0.8.h),

            // Location
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: 1.w),
                Expanded(
                  child: Text(
                    booking.clientLocation.address.isNotEmpty
                        ? booking.clientLocation.address
                        : 'Location not specified',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            SizedBox(height: 0.8.h),

            // Amount
            Row(
              children: [
                Icon(
                  Icons.payments_outlined,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: 1.w),
                Text(
                  'GH₵ ${booking.totalWithFees.toStringAsFixed(2)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            SizedBox(height: 1.5.h),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onMessage,
                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                    label: const Text('Message'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.h),
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onTrack,
                    icon: const Icon(Icons.track_changes_outlined, size: 16),
                    label: const Text('Track'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.h),
                    ),
                  ),
                ),
              ],
            ),

            if (onCancel != null) ...[
              SizedBox(height: 1.h),
              Center(
                child: TextButton.icon(
                  onPressed: onCancel,
                  icon: Icon(
                    Icons.close,
                    size: 14,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  label: Text(
                    'Cancel Booking',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
