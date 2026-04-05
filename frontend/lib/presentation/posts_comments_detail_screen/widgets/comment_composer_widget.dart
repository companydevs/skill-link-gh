import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Comment Composer Widget
/// Bottom sticky composer for writing new comments with emoji and photo attachment
class CommentComposerWidget extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onPost;

  const CommentComposerWidget({
    super.key,
    required this.controller,
    required this.onPost,
  });

  @override
  State<CommentComposerWidget> createState() => _CommentComposerWidgetState();
}

class _CommentComposerWidgetState extends State<CommentComposerWidget> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {
      _hasText = widget.controller.text.trim().isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Emoji picker button
            IconButton(
              icon: Icon(
                Icons.emoji_emotions_outlined,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 24,
              ),
              onPressed: () {
                // Emoji picker functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Emoji picker coming soon'),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),

            // Text input field
            Expanded(
              child: Container(
                constraints: BoxConstraints(maxHeight: 15.h),
                child: TextField(
                  controller: widget.controller,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24.0),
                      borderSide: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24.0),
                      borderSide: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24.0),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 1.h,
                    ),
                    filled: true,
                    fillColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),

            SizedBox(width: 2.w),

            // Photo attachment button
            if (!_hasText)
              IconButton(
                icon: Icon(
                  Icons.photo_camera,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 24,
                ),
                onPressed: () {
                  // Photo attachment functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Photo attachment coming soon'),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),

            // Post button
            if (_hasText)
              IconButton(
                icon: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.send,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 20,
                  ),
                ),
                onPressed: () {
                  widget.onPost(widget.controller.text);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }
}
