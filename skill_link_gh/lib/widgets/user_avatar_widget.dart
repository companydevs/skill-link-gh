import 'package:flutter/material.dart';

/// Default avatars for users without a profile photo
const kDefaultMaleAvatar =
    'https://cdn-icons-png.flaticon.com/512/3135/3135715.png';
const kDefaultFemaleAvatar =
    'https://cdn-icons-png.flaticon.com/512/6833/6833591.png';

class UserAvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final String? semanticLabel;

  /// Pass 'female' to use the female default. Defaults to male.
  final String? gender;

  const UserAvatarWidget({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = 40,
    this.semanticLabel,
    this.gender,
  });

  String get _defaultAvatar {
    final g = (gender ?? '').toLowerCase();
    return g == 'female' || g == 'f'
        ? kDefaultFemaleAvatar
        : kDefaultMaleAvatar;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveUrl = (imageUrl != null && imageUrl!.isNotEmpty)
        ? imageUrl!
        : _defaultAvatar;

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
        // On error, fall back to the flaticon default (never show initials)
        errorBuilder: (context, _, __) => Image.network(
          _defaultAvatar,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(context),
        ),
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
}
