import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Bottom sheet displaying full booking details
class BookingDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> booking;

  const BookingDetailsSheet({
    super.key,
    required this.booking,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bookingDate = booking['date'] as DateTime;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Booking Details',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: CustomIconWidget(
                    iconName: 'close',
                    color: theme.colorScheme.onSurface,
                    size: 6.w,
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.h),
            Row(
              children: [
                Container(
                  width: 15.w,
                  height: 15.w,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: CustomIconWidget(
                      iconName: booking['serviceIcon'] as String,
                      color: theme.colorScheme.primary,
                      size: 8.w,
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
                      ),
                      SizedBox(height: 0.5.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 2.w, vertical: 0.5.h),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                                  context, booking['status'] as String)
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
                ),
              ],
            ),
            SizedBox(height: 3.h),
            _buildDetailRow(
              context,
              'Booking ID',
              booking['bookingId'] as String,
            ),
            SizedBox(height: 2.h),
            _buildDetailRow(
              context,
              'Artisan',
              booking['artisanName'] as String,
            ),
            SizedBox(height: 2.h),
            _buildDetailRow(
              context,
              'Date',
              '${bookingDate.day}/${bookingDate.month}/${bookingDate.year}',
            ),
            SizedBox(height: 2.h),
            _buildDetailRow(
              context,
              'Time',
              booking['time'] as String,
            ),
            SizedBox(height: 2.h),
            _buildDetailRow(
              context,
              'Duration',
              booking['duration'] as String,
            ),
            SizedBox(height: 2.h),
            _buildDetailRow(
              context,
              'Price',
              booking['price'] as String,
            ),
            SizedBox(height: 2.h),
            _buildDetailRow(
              context,
              'Payment Status',
              booking['paymentStatus'] as String,
            ),
            SizedBox(height: 3.h),
            Text(
              'Service Description',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              booking['description'] as String,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'Location',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'location_on',
                  color: theme.colorScheme.primary,
                  size: 5.w,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    booking['location'] as String,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: CustomIconWidget(
                  iconName: 'directions',
                  color: theme.colorScheme.onPrimary,
                  size: 5.w,
                ),
                label: Text('Get Directions'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                ),
              ),
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
