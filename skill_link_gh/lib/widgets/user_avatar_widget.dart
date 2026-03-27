import 'package:flutter/material.dart';

/// Default male avatar used when no profile image is uploaded
const kDefaultMaleAvatar =
    'https://cdn-icons-png.flaticon.com/512/3135/3135715.png';

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
    final effectiveUrl = (imageUrl != null && imageUrl!.isNotEmpty)
        ? imageUrl!
        : kDefaultMaleAvatar;

    return ClipOval(
      child: Image.network(
        effectiveUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        semanticLabel: semanticLabel ?? name,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _placeholder(context);
        },
        errorBuilder: (context, _, __) {
          // Network failed — fall back to initials
          return _initialsAvatar();
        },
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: SizedBox(
          width: size * 0.4,
          height: size * 0.4,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _initialsAvatar() {
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join();

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
    ];
    final color = colors[name.hashCode.abs() % colors.length];

    return Container(
      width: size,
      height: size,
      color: color,
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.38,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
