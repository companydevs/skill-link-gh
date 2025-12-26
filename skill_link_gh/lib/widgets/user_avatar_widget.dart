import 'package:flutter/material.dart';

class UserAvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final String? semanticLabel;

  const UserAvatarWidget({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = 40,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // If we have a valid image URL, show the image
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          // Fallback to initials if image fails to load
          errorBuilder: (context, error, stackTrace) {
            return _buildInitialsAvatar(theme);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
              ),
              child: Center(
                child: SizedBox(
                  width: size * 0.5,
                  height: size * 0.5,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    // Show initials avatar if no image URL
    return _buildInitialsAvatar(theme);
  }

  Widget _buildInitialsAvatar(ThemeData theme) {
    final initials = _getInitials(name);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getColorFromName(name),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4, // Scale font size with avatar size
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    } else {
      return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'
          .toUpperCase();
    }
  }

  Color _getColorFromName(String name) {
    // Generate a consistent color based on the name
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
    ];

    final hash = name.hashCode;
    return colors[hash.abs() % colors.length];
  }
}
