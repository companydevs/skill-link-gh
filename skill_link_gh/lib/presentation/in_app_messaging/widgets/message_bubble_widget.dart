import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/user_avatar_widget.dart';

/// Message bubble widget for displaying individual messages
/// Supports text, images, voice messages, and booking cards
class MessageBubbleWidget extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isCurrentUser;
  final VoidCallback? onLongPress;
  final Function(String)? onReact;

  const MessageBubbleWidget({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.onLongPress,
    this.onReact,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final messageType = message['type'] as String? ?? 'text';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Row(
        mainAxisAlignment: isCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[_buildAvatar(context), SizedBox(width: 2.w)],
          Flexible(
            child: GestureDetector(
              onLongPress: onLongPress,
              child: Column(
                crossAxisAlignment: isCurrentUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  _buildMessageContent(context, messageType),
                  SizedBox(height: 0.5.h),
                  _buildMessageFooter(context),
                ],
              ),
            ),
          ),
          if (isCurrentUser) ...[SizedBox(width: 2.w), _buildAvatar(context)],
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final avatarUrl = message['avatar'] as String? ?? '';
    final label = message['avatarLabel'] as String? ?? '?';
    return UserAvatarWidget(
      imageUrl: avatarUrl.isNotEmpty ? avatarUrl : null,
      name: label,
      size: 8.w,
    );
  }

  Widget _buildMessageContent(BuildContext context, String messageType) {
    switch (messageType) {
      case 'image':
        return _buildImageMessage(context);
      case 'voice':
        return _buildVoiceMessage(context);
      case 'booking':
        return _buildBookingCard(context);
      case 'location':
        return _buildLocationMessage(context);
      default:
        return _buildTextMessage(context);
    }
  }

  Widget _buildTextMessage(BuildContext context) {
    final theme = Theme.of(context);
    final hasReaction = message['reaction'] != null;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          constraints: BoxConstraints(maxWidth: 70.w),
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
          decoration: BoxDecoration(
            color: isCurrentUser
                ? theme.colorScheme.primary
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(isCurrentUser ? 16 : 4),
              bottomRight: Radius.circular(isCurrentUser ? 4 : 16),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.08),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            message['content'] as String? ?? '',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isCurrentUser
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
        if (hasReaction)
          Positioned(
            bottom: -8,
            right: isCurrentUser ? 8 : null,
            left: isCurrentUser ? null : 8,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Text(
                message['reaction'] as String,
                style: TextStyle(fontSize: 14.sp),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImageMessage(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(maxWidth: 70.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CustomImageWidget(
          imageUrl: message['imageUrl'] as String? ?? '',
          width: 70.w,
          height: 30.h,
          fit: BoxFit.cover,
          semanticLabel: message['imageLabel'] as String? ?? 'Shared image',
        ),
      ),
    );
  }

  Widget _buildVoiceMessage(BuildContext context) {
    final theme = Theme.of(context);
    final duration = message['duration'] as String? ?? '0:00';

    return Container(
      constraints: BoxConstraints(maxWidth: 70.w),
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? theme.colorScheme.primary
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10.w,
            height: 10.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCurrentUser
                  ? theme.colorScheme.onPrimary.withValues(alpha: 0.2)
                  : theme.colorScheme.primary.withValues(alpha: 0.2),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: 'play_arrow',
                size: 20,
                color: isCurrentUser
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.primary,
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 3.h,
                  child: CustomPaint(
                    painter: WaveformPainter(
                      color: isCurrentUser
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.primary,
                    ),
                    size: Size(double.infinity, 3.h),
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  duration,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isCurrentUser
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context) {
    final theme = Theme.of(context);
    final bookingData = message['bookingData'] as Map<String, dynamic>? ?? {};

    return Container(
      constraints: BoxConstraints(maxWidth: 75.w),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'calendar_today',
                size: 20,
                color: theme.colorScheme.primary,
              ),
              SizedBox(width: 2.w),
              Text(
                'Booking Update',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            bookingData['service'] as String? ?? 'Service',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            bookingData['date'] as String? ?? 'Date',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              bookingData['status'] as String? ?? 'Status',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationMessage(BuildContext context) {
    final theme = Theme.of(context);
    final locationName = message['locationName'] as String? ?? 'Location';

    return Container(
      constraints: BoxConstraints(maxWidth: 70.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              height: 20.h,
              color: theme.colorScheme.surfaceContainerHighest,
              child: Center(
                child: CustomIconWidget(
                  iconName: 'location_on',
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    locationName,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 2.w),
                CustomIconWidget(
                  iconName: 'open_in_new',
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageFooter(BuildContext context) {
    final theme = Theme.of(context);
    final timestamp = message['timestamp'] as String? ?? '';
    final status = message['status'] as String? ?? 'sent';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          timestamp,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (isCurrentUser) ...[
          SizedBox(width: 1.w),
          CustomIconWidget(
            iconName: status == 'read'
                ? 'done_all'
                : status == 'delivered'
                ? 'done_all'
                : 'done',
            size: 14,
            color: status == 'read'
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ],
    );
  }
}

/// Custom painter for voice message waveform
class WaveformPainter extends CustomPainter {
  final Color color;

  WaveformPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final barCount = 20;
    final barWidth = size.width / barCount;
    final heights = [
      0.3,
      0.6,
      0.8,
      0.5,
      0.7,
      0.9,
      0.4,
      0.6,
      0.8,
      0.5,
      0.7,
      0.6,
      0.4,
      0.8,
      0.9,
      0.5,
      0.7,
      0.6,
      0.4,
      0.5,
    ];

    for (int i = 0; i < barCount; i++) {
      final x = i * barWidth + barWidth / 2;
      final barHeight = size.height * heights[i % heights.length];
      final y1 = (size.height - barHeight) / 2;
      final y2 = y1 + barHeight;

      canvas.drawLine(Offset(x, y1), Offset(x, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
