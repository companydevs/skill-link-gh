import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Action buttons widget for booking and messaging
class ActionButtonsWidget extends StatelessWidget {
  final VoidCallback onBookNow;
  final VoidCallback onMessage;

  const ActionButtonsWidget({
    super.key,
    required this.onBookNow,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: onBookNow,
                icon: CustomIconWidget(
                  iconName: 'calendar_today',
                  size: 20,
                  color: Colors.white,
                ),
                label: const Text('Book Now'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                ),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: OutlinedButton(
                onPressed: onMessage,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                ),
                child: CustomIconWidget(
                  iconName: 'chat_bubble_outline',
                  size: 24,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
