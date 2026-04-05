import 'package:cached_network_image/cached_network_image.dart';
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

  /// Shows a green online indicator dot when true.
  final bool isOnline;

  const UserAvatarWidget({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = 40,
    this.semanticLabel,
    this.gender,
    this.isOnline = false,
  });

  String get _defaultAvatar {
    final g = (gender ?? '').toLowerCase();
    return g == 'female' || g == 'f'
        ? kDefaultFemaleAvatar
        : kDefaultMaleAvatar;
  }

  @override
  Widget build(BuildContext context) {
    final hasRealUrl = imageUrl != null && imageUrl!.isNotEmpty;
    final effectiveUrl = hasRealUrl ? imageUrl! : _defaultAvatar;

    final avatar = ClipOval(
      child: CachedNetworkImage(
        imageUrl: effectiveUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, _) => _placeholder(context),
        errorWidget: (context, url, _) {
          if (url != _defaultAvatar) {
            return CachedNetworkImage(
              imageUrl: _defaultAvatar,
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholder: (context, _) => _placeholder(context),
              errorWidget: (context, _, __) => _placeholder(context),
            );
          }
          return _placeholder(context);
        },
      ),
    );

    if (!isOnline) return avatar;

    // Wrap with a Stack to overlay the green dot
    final dotSize = (size * 0.26).clamp(8.0, 16.0);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: dotSize * 0.2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.person,
        size: size * 0.6,
        color: Theme.of(
          context,
        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
    );
  }
}
