import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Individual booking card widget displaying booking details and actions
class BookingCardWidget extends StatelessWidget {
  final Map<String, dynamic> booking;
  final String bookingStatus;
  final VoidCallback onTap;
  final VoidCallback onMessage;
  final VoidCallback? onReschedule;
  final VoidCallback? onCancel;
  final VoidCallback? onReview;
  final VoidCallback? onRequestPayment;

  const BookingCardWidget({
    super.key,
    required this.booking,
    required this.bookingStatus,
    required this.onTap,
    required this.onMessage,
    this.onReschedule,
    this.onCancel,
    this.onReview,
    this.onRequestPayment,
  });

  Color _getStatusColor(BuildContext context, String status) {
    final theme = Theme.of(context);
    switch (status.toLowerCase()) {
      case 'confirmed':
        return theme.colorScheme.tertiary;
      case 'pending':
        return const Color(0xFFFFC107);
      case 'cancelled':
        return theme.colorScheme.error;
      case 'in-progress':
        return theme.colorScheme.primary;
      case 'completed':
        return const Color(0xFF4CAF50);
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  String _getCountdownText(DateTime bookingDate) {
    final now = DateTime.now();
    final difference = bookingDate.difference(now);

    if (difference.isNegative) return 'Started';

    if (difference.inDays > 0) {
      return '${difference.inDays}d ${difference.inHours % 24}h';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else {
      return '${difference.inMinutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bookingDate = booking['date'] as DateTime;
    final showCountdown =
        bookingStatus == 'Upcoming' && bookingDate.isAfter(DateTime.now());

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12.w,
                    height: 12.w,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: CustomIconWidget(
                        iconName: booking['serviceIcon'] as String,
                        color: theme.colorScheme.primary,
                        size: 6.w,
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking['serviceType'] as String,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          booking['artisanName'] as String,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color:
                          _getStatusColor(context, booking['status'] as String)
                              .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      booking['status'] as String,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _getStatusColor(
                            context, booking['status'] as String),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'calendar_today',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 4.w,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    '${bookingDate.day}/${bookingDate.month}/${bookingDate.year}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  SizedBox(width: 4.w),
                  CustomIconWidget(
                    iconName: 'access_time',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 4.w,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    booking['time'] as String,
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (showCountdown) ...[
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 2.w, vertical: 0.5.h),
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.tertiary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomIconWidget(
                            iconName: 'schedule',
                            color: theme.colorScheme.tertiary,
                            size: 3.w,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            _getCountdownText(bookingDate),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.tertiary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 2.h),
              if (bookingStatus == 'Upcoming') ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onMessage,
                        icon: CustomIconWidget(
                          iconName: 'chat_bubble_outline',
                          color: theme.colorScheme.primary,
                          size: 4.w,
                        ),
                        label: Text('Message'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 1.5.h),
                        ),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReschedule,
                        icon: CustomIconWidget(
                          iconName: 'event',
                          color: theme.colorScheme.primary,
                          size: 4.w,
                        ),
                        label: Text('Reschedule'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 1.5.h),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: onCancel,
                    icon: CustomIconWidget(
                      iconName: 'close',
                      color: theme.colorScheme.error,
                      size: 4.w,
                    ),
                    label: Text('Cancel Booking'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    ),
                  ),
                ),
              ],
              if (bookingStatus == 'Completed') ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onReview,
                        icon: CustomIconWidget(
                          iconName: 'star_outline',
                          color: theme.colorScheme.onPrimary,
                          size: 4.w,
                        ),
                        label: Text('Review & Rate'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 1.5.h),
                        ),
                      ),
                    ),
                    if (onRequestPayment != null) ...[
                      SizedBox(width: 2.w),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onRequestPayment,
                          icon: CustomIconWidget(
                            iconName: 'payment',
                            color: theme.colorScheme.primary,
                            size: 4.w,
                          ),
                          label: Text('Payment'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 1.5.h),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              if (bookingStatus == 'Cancelled') ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onMessage,
                    icon: CustomIconWidget(
                      iconName: 'chat_bubble_outline',
                      color: theme.colorScheme.primary,
                      size: 4.w,
                    ),
                    label: Text('Contact Support'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
