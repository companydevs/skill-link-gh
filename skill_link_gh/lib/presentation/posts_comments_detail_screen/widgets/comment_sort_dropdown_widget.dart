import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Comment Sort Dropdown Widget
/// Provides sorting options for comments (newest, oldest, most liked)
class CommentSortDropdownWidget extends StatelessWidget {
  final String currentSort;
  final Function(String) onSortChanged;

  const CommentSortDropdownWidget({
    super.key,
    required this.currentSort,
    required this.onSortChanged,
  });

  String _getSortLabel(String sortKey) {
    switch (sortKey) {
      case 'newest':
        return 'Newest';
      case 'oldest':
        return 'Oldest';
      case 'most_liked':
        return 'Most Liked';
      default:
        return 'Newest';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.sort, color: Theme.of(context).colorScheme.onSurface),
      tooltip: 'Sort comments',
      offset: Offset(0, 6.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      onSelected: onSortChanged,
      itemBuilder:
          (context) => [
            PopupMenuItem(
              value: 'newest',
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 20,
                    color:
                        currentSort == 'newest'
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    'Newest First',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color:
                          currentSort == 'newest'
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                      fontWeight:
                          currentSort == 'newest'
                              ? FontWeight.w600
                              : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'oldest',
              child: Row(
                children: [
                  Icon(
                    Icons.history,
                    size: 20,
                    color:
                        currentSort == 'oldest'
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    'Oldest First',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color:
                          currentSort == 'oldest'
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                      fontWeight:
                          currentSort == 'oldest'
                              ? FontWeight.w600
                              : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'most_liked',
              child: Row(
                children: [
                  Icon(
                    Icons.favorite,
                    size: 20,
                    color:
                        currentSort == 'most_liked'
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    'Most Liked',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color:
                          currentSort == 'most_liked'
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                      fontWeight:
                          currentSort == 'most_liked'
                              ? FontWeight.w600
                              : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
    );
  }
}
