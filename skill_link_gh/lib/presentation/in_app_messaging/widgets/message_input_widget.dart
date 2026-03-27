import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Message input widget with text field, attachments, and voice recording
class MessageInputWidget extends StatefulWidget {
  final Function(String) onSendMessage;
  final Function(String) onSendImage;
  final Function(String) onSendVoice;
  final Function() onSendLocation;
  final Function(bool)? onTypingChanged;

  const MessageInputWidget({
    super.key,
    required this.onSendMessage,
    required this.onSendImage,
    required this.onSendVoice,
    required this.onSendLocation,
    this.onTypingChanged,
  });

  @override
  State<MessageInputWidget> createState() => _MessageInputWidgetState();
}

class _MessageInputWidgetState extends State<MessageInputWidget> {
  final TextEditingController _messageController = TextEditingController();
  bool _isTyping = false;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final typing = _messageController.text.trim().isNotEmpty;
    if (typing != _isTyping) {
      widget.onTypingChanged?.call(typing);
    }
    setState(() {
      _isTyping = typing;
    });
  }

  void _handleSendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      widget.onSendMessage(message);
      _messageController.clear();
    }
  }

  void _showAttachmentOptions() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 2.h),
              Container(
                width: 12.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(height: 3.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Column(
                  children: [
                    _buildAttachmentOption(
                      icon: 'photo_library',
                      label: 'Photo',
                      color: theme.colorScheme.primary,
                      onTap: () {
                        Navigator.pop(context);
                        widget.onSendImage(
                          'https://images.pexels.com/photos/1181406/pexels-photo-1181406.jpeg',
                        );
                      },
                    ),
                    SizedBox(height: 2.h),
                    _buildAttachmentOption(
                      icon: 'location_on',
                      label: 'Location',
                      color: theme.colorScheme.secondary,
                      onTap: () {
                        Navigator.pop(context);
                        widget.onSendLocation();
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 3.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required String icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CustomIconWidget(iconName: icon, size: 24, color: color),
              ),
            ),
            SizedBox(width: 4.w),
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });

    if (!_isRecording) {
      widget.onSendVoice(
        'voice_message_${DateTime.now().millisecondsSinceEpoch}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: _isRecording ? _buildRecordingUI() : _buildInputUI(),
      ),
    );
  }

  Widget _buildInputUI() {
    final theme = Theme.of(context);

    return Row(
      children: [
        IconButton(
          onPressed: _showAttachmentOptions,
          icon: CustomIconWidget(
            iconName: 'add_circle_outline',
            size: 28,
            color: theme.colorScheme.primary,
          ),
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(minWidth: 10.w, minHeight: 10.w),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: Container(
            constraints: BoxConstraints(minHeight: 6.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextField(
              controller: _messageController,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 4.w,
                  vertical: 1.5.h,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 2.w),
        _isTyping
            ? IconButton(
                onPressed: _handleSendMessage,
                icon: Container(
                  width: 10.w,
                  height: 10.w,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: CustomIconWidget(
                      iconName: 'send',
                      size: 20,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(minWidth: 10.w, minHeight: 10.w),
              )
            : IconButton(
                onPressed: _toggleRecording,
                icon: CustomIconWidget(
                  iconName: 'mic',
                  size: 28,
                  color: theme.colorScheme.primary,
                ),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(minWidth: 10.w, minHeight: 10.w),
              ),
      ],
    );
  }

  Widget _buildRecordingUI() {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Container(
                  width: 3.w,
                  height: 3.w,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 3.w),
                Text(
                  'Recording...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Spacer(),
                Text(
                  '0:00',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 2.w),
        IconButton(
          onPressed: _toggleRecording,
          icon: Container(
            width: 10.w,
            height: 10.w,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: 'stop',
                size: 20,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(minWidth: 10.w, minHeight: 10.w),
        ),
      ],
    );
  }
}
