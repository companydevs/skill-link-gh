import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// App bar variant types
enum AppBarVariant {
  /// Standard app bar with title and actions
  standard,

  /// Centered title variant
  centered,

  /// Search variant with search field
  search,

  /// Transparent variant for overlays
  transparent,

  /// Large title variant (iOS style)
  large,
}

/// Custom app bar widget for SkillLink GH
/// Implements clean, professional navigation with platform-appropriate patterns
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// App bar title
  final String? title;

  /// Leading widget (typically back button or menu)
  final Widget? leading;

  /// Action widgets displayed on the right
  final List<Widget>? actions;

  /// App bar variant
  final AppBarVariant variant;

  /// Whether to show back button automatically
  final bool automaticallyImplyLeading;

  /// Background color override
  final Color? backgroundColor;

  /// Foreground color override
  final Color? foregroundColor;

  /// Elevation override
  final double? elevation;

  /// Bottom widget (typically TabBar)
  final PreferredSizeWidget? bottom;

  /// Callback for search field changes (when variant is search)
  final ValueChanged<String>? onSearchChanged;

  /// Search field hint text
  final String searchHint;

  /// Whether to show shadow
  final bool showShadow;

  /// Custom title widget (overrides title string)
  final Widget? titleWidget;

  const CustomAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.variant = AppBarVariant.standard,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.bottom,
    this.onSearchChanged,
    this.searchHint = 'Search services...',
    this.showShadow = true,
    this.titleWidget,
  });

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    final baseHeight = variant == AppBarVariant.large ? 96.0 : 56.0;
    return Size.fromHeight(baseHeight + bottomHeight);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    switch (variant) {
      case AppBarVariant.search:
        return _buildSearchAppBar(context, theme, colorScheme);
      case AppBarVariant.transparent:
        return _buildTransparentAppBar(context, theme, colorScheme);
      case AppBarVariant.large:
        return _buildLargeAppBar(context, theme, colorScheme);
      case AppBarVariant.centered:
        return _buildCenteredAppBar(context, theme, colorScheme);
      case AppBarVariant.standard:
      default:
        return _buildStandardAppBar(context, theme, colorScheme);
    }
  }

  Widget _buildStandardAppBar(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return AppBar(
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      title: titleWidget ?? (title != null ? Text(title!) : null),
      actions: actions,
      backgroundColor: backgroundColor ?? colorScheme.surface,
      foregroundColor: foregroundColor ?? colorScheme.onSurface,
      elevation: showShadow ? (elevation ?? 0) : 0,
      centerTitle: false,
      bottom: bottom,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: theme.brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
      ),
      surfaceTintColor: Colors.transparent,
      shadowColor: showShadow ? colorScheme.shadow : Colors.transparent,
    );
  }

  Widget _buildCenteredAppBar(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return AppBar(
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      title: titleWidget ?? (title != null ? Text(title!) : null),
      actions: actions,
      backgroundColor: backgroundColor ?? colorScheme.surface,
      foregroundColor: foregroundColor ?? colorScheme.onSurface,
      elevation: showShadow ? (elevation ?? 0) : 0,
      centerTitle: true,
      bottom: bottom,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: theme.brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
      ),
      surfaceTintColor: Colors.transparent,
      shadowColor: showShadow ? colorScheme.shadow : Colors.transparent,
    );
  }

  Widget _buildSearchAppBar(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return AppBar(
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      title: Container(
        height: 40,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: TextField(
          onChanged: onSearchChanged,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: searchHint,
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            prefixIcon: Icon(
              Icons.search,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
          ),
        ),
      ),
      actions: actions,
      backgroundColor: backgroundColor ?? colorScheme.surface,
      foregroundColor: foregroundColor ?? colorScheme.onSurface,
      elevation: showShadow ? (elevation ?? 0) : 0,
      bottom: bottom,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: theme.brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
      ),
      surfaceTintColor: Colors.transparent,
      shadowColor: showShadow ? colorScheme.shadow : Colors.transparent,
    );
  }

  Widget _buildTransparentAppBar(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return AppBar(
      leading: leading ??
          (automaticallyImplyLeading && Navigator.canPop(context)
              ? Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    color: Colors.white,
                    onPressed: () => Navigator.pop(context),
                  ),
                )
              : null),
      automaticallyImplyLeading: false,
      title: titleWidget ?? (title != null ? Text(title!) : null),
      actions: actions
              ?.map((action) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: action,
                  ))
              .toList() ??
          [],
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      bottom: bottom,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  Widget _buildLargeAppBar(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return SliverAppBar(
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      title: titleWidget ?? (title != null ? Text(title!) : null),
      actions: actions,
      backgroundColor: backgroundColor ?? colorScheme.surface,
      foregroundColor: foregroundColor ?? colorScheme.onSurface,
      elevation: showShadow ? (elevation ?? 0) : 0,
      expandedHeight: 96,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: titleWidget ?? (title != null ? Text(title!) : null),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
      ),
      bottom: bottom,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: theme.brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
      ),
      surfaceTintColor: Colors.transparent,
      shadowColor: showShadow ? colorScheme.shadow : Colors.transparent,
    );
  }
}

/// Helper widget for app bar action buttons with consistent styling
class AppBarAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final int? badgeCount;

  const AppBarAction({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget iconButton = IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      tooltip: tooltip,
      iconSize: 24,
    );

    if (badgeCount != null && badgeCount! > 0) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          iconButton,
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.error,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                badgeCount! > 99 ? '99+' : badgeCount.toString(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onError,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }

    return iconButton;
  }
}
