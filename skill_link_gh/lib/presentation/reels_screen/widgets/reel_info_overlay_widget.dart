import 'package:flutter/material.dart';

import '../../../widgets/user_avatar_widget.dart';

/// Bottom-left info overlay — Instagram Reels style
class ReelInfoOverlayWidget extends StatelessWidget {
  final String artisanName;
  final String artisanAvatar;
  final String artisanAvatarSemanticLabel;
  final String category;
  final String description;
  final VoidCallback onProfileTap;

  const ReelInfoOverlayWidget({
    super.key,
    required this.artisanName,
    required this.artisanAvatar,
    required this.artisanAvatarSemanticLabel,
    required this.category,
    required this.description,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar + name + follow
        GestureDetector(
          onTap: onProfileTap,
          child: Row(
            children: [
              // Avatar with white ring
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: UserAvatarWidget(
                  imageUrl: artisanAvatar,
                  name: artisanName,
                  size: 40,
                  semanticLabel: artisanAvatarSemanticLabel,
                ),
              ),
              const SizedBox(width: 10),
              // Name — truncated like Instagram
              Flexible(
                child: Text(
                  artisanName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              // Follow button — outlined white pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 1.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Follow',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Description
        Text(
          description,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.4,
            shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
