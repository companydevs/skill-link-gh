import 'package:flutter/material.dart';

/// TikTok-style create content bottom sheet
/// Shows options for creating posts or reels
class CreateContentBottomSheet extends StatelessWidget {
  final VoidCallback? onCreatePost;
  final VoidCallback? onCreateReel;
  final VoidCallback? onGoLive;

  const CreateContentBottomSheet({
    super.key,
    this.onCreatePost,
    this.onCreateReel,
    this.onGoLive,
  });

  static void show(
    BuildContext context, {
    VoidCallback? onCreatePost,
    VoidCallback? onCreateReel,
    VoidCallback? onGoLive,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CreateContentBottomSheet(
        onCreatePost: onCreatePost,
        onCreateReel: onCreateReel,
        onGoLive: onGoLive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                'Create',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const Divider(height: 1),

            // Options
            _buildOption(
              context,
              icon: Icons.video_library_outlined,
              title: 'Create Reel',
              subtitle: 'Record or upload a video',
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.secondary],
              ),
              onTap: () {
                Navigator.pop(context);
                onCreateReel?.call();
              },
            ),

            _buildOption(
              context,
              icon: Icons.photo_library_outlined,
              title: 'Create Post',
              subtitle: 'Share photos and updates',
              gradient: LinearGradient(colors: [Colors.purple, Colors.pink]),
              onTap: () {
                Navigator.pop(context);
                onCreatePost?.call();
              },
            ),

            if (onGoLive != null)
              _buildOption(
                context,
                icon: Icons.videocam_outlined,
                title: 'Go Live',
                subtitle: 'Start a live stream',
                gradient: LinearGradient(colors: [Colors.red, Colors.orange]),
                onTap: () {
                  Navigator.pop(context);
                  onGoLive?.call();
                },
              ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            // Icon with gradient background
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),

            const SizedBox(width: 16),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
