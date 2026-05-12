import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_link_gh/provider/user_type_provider.dart';

/// TikTok-style bottom navigation bar with center create button
/// Features a prominent center button for creating content (artisans only)
class TikTokBottomBar extends ConsumerWidget {
  /// Current selected index (0-4, where 2 is the center create button)
  final int currentIndex;

  /// Callback when navigation item is tapped
  final ValueChanged<int>? onTap;

  /// Callback when create button is tapped
  final VoidCallback? onCreateTap;

  /// Badge count for specific items (optional)
  final Map<int, int>? badges;

  const TikTokBottomBar({
    super.key,
    required this.currentIndex,
    this.onTap,
    this.onCreateTap,
    this.badges,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Check if user is artisan
    final isArtisanAsync = ref.watch(isArtisanProvider);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: isArtisanAsync.when(
            data: (isArtisan) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Home
                _buildNavItem(
                  context,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Home',
                  index: 0,
                  isSelected: currentIndex == 0,
                ),

                // Reels/Discover
                _buildNavItem(
                  context,
                  icon: Icons.play_circle_outline,
                  activeIcon: Icons.play_circle,
                  label: 'Reels',
                  index: 1,
                  isSelected: currentIndex == 1,
                ),

                // Center Create Button (only for artisans)
                if (isArtisan) _buildCreateButton(context, isDark),

                // Messages
                _buildNavItem(
                  context,
                  icon: Icons.chat_bubble_outline,
                  activeIcon: Icons.chat_bubble,
                  label: 'Inbox',
                  index: 3,
                  isSelected: currentIndex == 3,
                  badgeCount: badges?[3],
                ),

                // Profile
                _buildNavItem(
                  context,
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profile',
                  index: 4,
                  isSelected: currentIndex == 4,
                ),
              ],
            ),
            loading: () => Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildNavItem(
                  context,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Home',
                  index: 0,
                  isSelected: currentIndex == 0,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.play_circle_outline,
                  activeIcon: Icons.play_circle,
                  label: 'Reels',
                  index: 1,
                  isSelected: currentIndex == 1,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.chat_bubble_outline,
                  activeIcon: Icons.chat_bubble,
                  label: 'Inbox',
                  index: 3,
                  isSelected: currentIndex == 3,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profile',
                  index: 4,
                  isSelected: currentIndex == 4,
                ),
              ],
            ),
            error: (_, __) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildNavItem(
                  context,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Home',
                  index: 0,
                  isSelected: currentIndex == 0,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.play_circle_outline,
                  activeIcon: Icons.play_circle,
                  label: 'Reels',
                  index: 1,
                  isSelected: currentIndex == 1,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.chat_bubble_outline,
                  activeIcon: Icons.chat_bubble,
                  label: 'Inbox',
                  index: 3,
                  isSelected: currentIndex == 3,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profile',
                  index: 4,
                  isSelected: currentIndex == 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required bool isSelected,
    int? badgeCount,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: InkWell(
        onTap: () {
          if (!isSelected) {
            HapticFeedback.lightImpact();
            onTap?.call(index);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isSelected ? activeIcon : icon,
                    size: 26,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  if (badgeCount != null && badgeCount > 0)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          badgeCount > 9 ? '9+' : badgeCount.toString(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onError,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateButton(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          onCreateTap?.call();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // TikTok-style dual-color button
              Container(
                width: 44,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.secondary],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Left side accent
                    Positioned(
                      left: -4,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00F2EA),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    // Right side accent
                    Positioned(
                      right: -4,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF0050),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    // Center white background
                    Center(
                      child: Container(
                        width: 32,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.add,
                          size: 20,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Create',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
