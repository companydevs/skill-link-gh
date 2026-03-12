import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/booking_card_widget.dart';
import './widgets/booking_details_sheet.dart';
import './widgets/booking_filter_sheet.dart';
import './widgets/empty_state_widget.dart';

/// Booking Management screen for comprehensive appointment overview and control
class BookingManagement extends StatefulWidget {
  const BookingManagement({super.key});

  @override
  State<BookingManagement> createState() => _BookingManagementState();
}

class _BookingManagementState extends State<BookingManagement>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedStatus = 'Upcoming';
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  bool _isRefreshing = false;

  final List<String> _statusOptions = ['Upcoming', 'Completed', 'Cancelled'];

  // Mock booking data
  final List<Map<String, dynamic>> _allBookings = [
    {
      'bookingId': 'BK001',
      'serviceType': 'Plumbing Repair',
      'serviceIcon': 'plumbing',
      'artisanName': 'Kwame Mensah',
      'date': DateTime.now().add(Duration(days: 2)),
      'time': '10:00 AM',
      'duration': '2 hours',
      'status': 'Confirmed',
      'price': 'GHS 150.00',
      'paymentStatus': 'Pending',
      'description':
          'Fix leaking kitchen sink and replace worn-out pipes. Includes inspection of water pressure and drainage system.',
      'location': '123 Independence Avenue, Accra',
    },
    {
      'bookingId': 'BK002',
      'serviceType': 'Electrical Work',
      'serviceIcon': 'electrical_services',
      'artisanName': 'Ama Osei',
      'date': DateTime.now().add(Duration(days: 5)),
      'time': '2:00 PM',
      'duration': '3 hours',
      'status': 'Pending',
      'price': 'GHS 200.00',
      'paymentStatus': 'Pending',
      'description':
          'Install new ceiling fan and repair faulty light switches in living room and bedroom.',
      'location': '45 Cantonments Road, Accra',
    },
    {
      'bookingId': 'BK003',
      'serviceType': 'Carpentry',
      'serviceIcon': 'carpenter',
      'artisanName': 'Kofi Asante',
      'date': DateTime.now().subtract(Duration(days: 10)),
      'time': '9:00 AM',
      'duration': '4 hours',
      'status': 'Completed',
      'price': 'GHS 300.00',
      'paymentStatus': 'Paid',
      'description':
          'Custom wardrobe installation with shelving and drawers. Includes measurements and material sourcing.',
      'location': '78 Osu Oxford Street, Accra',
    },
    {
      'bookingId': 'BK004',
      'serviceType': 'Painting',
      'serviceIcon': 'format_paint',
      'artisanName': 'Abena Boateng',
      'date': DateTime.now().subtract(Duration(days: 5)),
      'time': '8:00 AM',
      'duration': '6 hours',
      'status': 'Completed',
      'price': 'GHS 450.00',
      'paymentStatus': 'Paid',
      'description':
          'Interior painting of two bedrooms including wall preparation, primer application, and two coats of paint.',
      'location': '12 Labone Crescent, Accra',
    },
    {
      'bookingId': 'BK005',
      'serviceType': 'AC Repair',
      'serviceIcon': 'ac_unit',
      'artisanName': 'Yaw Owusu',
      'date': DateTime.now().subtract(Duration(days: 15)),
      'time': '11:00 AM',
      'duration': '2 hours',
      'status': 'Cancelled',
      'price': 'GHS 180.00',
      'paymentStatus': 'Refunded',
      'description':
          'Air conditioning unit maintenance and gas refill. Cancelled due to scheduling conflict.',
      'location': '56 East Legon, Accra',
    },
    {
      'bookingId': 'BK006',
      'serviceType': 'Tiling',
      'serviceIcon': 'grid_on',
      'artisanName': 'Akua Darko',
      'date': DateTime.now().add(Duration(hours: 5)),
      'time': '1:00 PM',
      'duration': '5 hours',
      'status': 'In-Progress',
      'price': 'GHS 500.00',
      'paymentStatus': 'Partial',
      'description':
          'Bathroom floor and wall tiling with waterproofing. Currently in progress.',
      'location': '34 Airport Residential, Accra',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredBookings() {
    List<Map<String, dynamic>> filtered = _allBookings.where((booking) {
      final status = booking['status'] as String;
      final bookingDate = booking['date'] as DateTime;

      bool statusMatch = false;
      if (_selectedStatus == 'Upcoming') {
        statusMatch =
            status == 'Confirmed' ||
            status == 'Pending' ||
            status == 'In-Progress';
      } else if (_selectedStatus == 'Completed') {
        statusMatch = status == 'Completed';
      } else if (_selectedStatus == 'Cancelled') {
        statusMatch = status == 'Cancelled';
      }

      bool dateMatch = true;
      if (_filterStartDate != null && _filterEndDate != null) {
        dateMatch =
            bookingDate.isAfter(
              _filterStartDate!.subtract(Duration(days: 1)),
            ) &&
            bookingDate.isBefore(_filterEndDate!.add(Duration(days: 1)));
      }

      return statusMatch && dateMatch;
    }).toList();

    filtered.sort((a, b) {
      final dateA = a['date'] as DateTime;
      final dateB = b['date'] as DateTime;
      return _selectedStatus == 'Upcoming'
          ? dateA.compareTo(dateB)
          : dateB.compareTo(dateA);
    });

    return filtered;
  }

  Future<void> _refreshBookings() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(Duration(seconds: 1));
    setState(() => _isRefreshing = false);
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

  void _showBookingDetails(Map<String, dynamic> booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookingDetailsSheet(booking: booking),
    );
  }

  void _handleMessage(Map<String, dynamic> booking) {
    Navigator.pushNamed(context, '/in-app-messaging');
  }

  void _handleReschedule(Map<String, dynamic> booking) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reschedule booking ${booking['bookingId']}'),
        action: SnackBarAction(label: 'OK', onPressed: () {}),
      ),
    );
  }

  void _handleCancel(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Booking'),
        content: Text(
          'Are you sure you want to cancel this booking? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Booking cancelled successfully')),
              );
            },
            child: Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _handleReview(Map<String, dynamic> booking) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Review artisan ${booking['artisanName']}'),
        action: SnackBarAction(label: 'RATE', onPressed: () {}),
      ),
    );
  }

  void _handleRequestPayment(Map<String, dynamic> booking) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment request sent for ${booking['bookingId']}'),
      ),
    );
  }

  void _handleAddToCalendar(Map<String, dynamic> booking) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Added to calendar')));
  }

  void _handleGetDirections(Map<String, dynamic> booking) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening directions to ${booking['location']}')),
    );
  }

  void _createNewBooking() {
    Navigator.pushNamed(context, '/service-booking');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredBookings = _getFilteredBookings();

    return Scaffold(
      appBar: CustomAppBar(
        variant: AppBarVariant.standard,
        title: 'Bookings',
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Notifications')));
            },
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
          Container(
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
          if (_filterStartDate != null && _filterEndDate != null)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'filter_list',
                    color: theme.colorScheme.primary,
                    size: 4.w,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Filtered: ${_filterStartDate!.day}/${_filterStartDate!.month}/${_filterStartDate!.year} - ${_filterEndDate!.day}/${_filterEndDate!.month}/${_filterEndDate!.year}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _filterStartDate = null;
                        _filterEndDate = null;
                      });
                    },
                    icon: CustomIconWidget(
                      iconName: 'close',
                      color: theme.colorScheme.primary,
                      size: 4.w,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
            ),
          SizedBox(height: 1.h),
          Expanded(
            child: filteredBookings.isEmpty
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
                    onButtonPressed: _createNewBooking,
                  )
                : RefreshIndicator(
                    onRefresh: _refreshBookings,
                    child: ListView.builder(
                      padding: EdgeInsets.only(bottom: 2.h),
                      itemCount: filteredBookings.length,
                      itemBuilder: (context, index) {
                        final booking = filteredBookings[index];
                        return Slidable(
                          key: ValueKey(booking['bookingId']),
                          endActionPane: _selectedStatus == 'Upcoming'
                              ? ActionPane(
                                  motion: const ScrollMotion(),
                                  children: [
                                    SlidableAction(
                                      onPressed: (_) =>
                                          _handleAddToCalendar(booking),
                                      backgroundColor:
                                          theme.colorScheme.primary,
                                      foregroundColor:
                                          theme.colorScheme.onPrimary,
                                      icon: Icons.calendar_today,
                                      label: 'Calendar',
                                    ),
                                    SlidableAction(
                                      onPressed: (_) =>
                                          _handleGetDirections(booking),
                                      backgroundColor:
                                          theme.colorScheme.tertiary,
                                      foregroundColor:
                                          theme.colorScheme.onPrimary,
                                      icon: Icons.directions,
                                      label: 'Directions',
                                    ),
                                  ],
                                )
                              : null,
                          child: BookingCardWidget(
                            booking: booking,
                            bookingStatus: _selectedStatus,
                            onTap: () => _showBookingDetails(booking),
                            onMessage: () => _handleMessage(booking),
                            onReschedule: _selectedStatus == 'Upcoming'
                                ? () => _handleReschedule(booking)
                                : null,
                            onCancel: _selectedStatus == 'Upcoming'
                                ? () => _handleCancel(booking)
                                : null,
                            onReview: _selectedStatus == 'Completed'
                                ? () => _handleReview(booking)
                                : null,
                            onRequestPayment: _selectedStatus == 'Completed'
                                ? () => _handleRequestPayment(booking)
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "booking_create", // Add unique hero tag
        onPressed: _createNewBooking,
        icon: CustomIconWidget(
          iconName: 'add',
          color: theme.colorScheme.onPrimary,
          size: 6.w,
        ),
        label: Text('New Booking'),
      ),
      bottomNavigationBar: CustomBottomBar(currentIndex: 4),
    );
  }
}
