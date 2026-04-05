import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Search bar widget with voice input support and recent searches overlay
class SearchBarWidget extends StatefulWidget {
  final Function(String) onSearchChanged;
  final Function(String) onSearchSubmitted;
  final VoidCallback onVoiceSearch;
  final List<String> recentSearches;
  final Function(String) onRecentSearchTap;

  const SearchBarWidget({
    super.key,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.onVoiceSearch,
    required this.recentSearches,
    required this.onRecentSearchTap,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (_searchFocusNode.hasFocus && widget.recentSearches.isNotEmpty) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();
    final overlay = Overlay.of(context);
    final theme = Theme.of(context);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 8.w,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, 7.h + 8),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: theme.colorScheme.surface,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 28.h),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(vertical: 1.h),
                itemCount: widget.recentSearches.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
                itemBuilder: (context, index) {
                  final search = widget.recentSearches[index];
                  return ListTile(
                    leading: CustomIconWidget(
                      iconName: 'history',
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    title: Text(search, style: theme.textTheme.bodyMedium),
                    onTap: () {
                      _searchController.text = search;
                      widget.onRecentSearchTap(search);
                      _searchFocusNode.unfocus();
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _removeOverlay();
    _searchController.dispose();
    _searchFocusNode.removeListener(_onFocusChanged);
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        height: 7.h,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          onChanged: widget.onSearchChanged,
          onSubmitted: widget.onSearchSubmitted,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Search for services or artisans...',
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            prefixIcon: Padding(
              padding: EdgeInsets.all(2.w),
              child: CustomIconWidget(
                iconName: 'search',
                color: theme.colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: CustomIconWidget(
                      iconName: 'close',
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      widget.onSearchChanged('');
                    },
                  ),
                IconButton(
                  icon: CustomIconWidget(
                    iconName: 'mic',
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  onPressed: widget.onVoiceSearch,
                ),
              ],
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 4.w,
              vertical: 2.h,
            ),
          ),
        ),
      ),
    );
  }
}
