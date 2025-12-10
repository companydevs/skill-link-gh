import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Filter bottom sheet widget for advanced filtering options
class FilterBottomSheetWidget extends StatefulWidget {
  final Map<String, dynamic> currentFilters;
  final Function(Map<String, dynamic>) onApplyFilters;

  const FilterBottomSheetWidget({
    super.key,
    required this.currentFilters,
    required this.onApplyFilters,
  });

  @override
  State<FilterBottomSheetWidget> createState() =>
      _FilterBottomSheetWidgetState();
}

class _FilterBottomSheetWidgetState extends State<FilterBottomSheetWidget> {
  late Map<String, dynamic> _filters;

  @override
  void initState() {
    super.initState();
    _filters = Map.from(widget.currentFilters);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: EdgeInsets.only(top: 1.h),
            width: 12.w,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filters = {
                        'distance': 10.0,
                        'minPrice': 0.0,
                        'maxPrice': 1000.0,
                        'minRating': 0.0,
                        'availability': 'any',
                        'verifiedOnly': false,
                      };
                    });
                  },
                  child: Text('Reset'),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Distance Radius',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _filters['distance'] as double,
                          min: 1,
                          max: 50,
                          divisions: 49,
                          label:
                              '${(_filters['distance'] as double).round()} km',
                          onChanged: (value) {
                            setState(() {
                              _filters['distance'] = value;
                            });
                          },
                        ),
                      ),
                      Text(
                        '${(_filters['distance'] as double).round()} km',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Price Range (GHS)',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  RangeSlider(
                    values: RangeValues(
                      _filters['minPrice'] as double,
                      _filters['maxPrice'] as double,
                    ),
                    min: 0,
                    max: 1000,
                    divisions: 100,
                    labels: RangeLabels(
                      'GHS ${(_filters['minPrice'] as double).round()}',
                      'GHS ${(_filters['maxPrice'] as double).round()}',
                    ),
                    onChanged: (values) {
                      setState(() {
                        _filters['minPrice'] = values.start;
                        _filters['maxPrice'] = values.end;
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'GHS ${(_filters['minPrice'] as double).round()}',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        'GHS ${(_filters['maxPrice'] as double).round()}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Minimum Rating',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _filters['minRating'] as double,
                          min: 0,
                          max: 5,
                          divisions: 10,
                          label:
                              '${(_filters['minRating'] as double).toStringAsFixed(1)} ★',
                          onChanged: (value) {
                            setState(() {
                              _filters['minRating'] = value;
                            });
                          },
                        ),
                      ),
                      Text(
                        '${(_filters['minRating'] as double).toStringAsFixed(1)} ★',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Availability',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Wrap(
                    spacing: 2.w,
                    children: [
                      ChoiceChip(
                        label: Text('Any Time'),
                        selected: _filters['availability'] == 'any',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _filters['availability'] = 'any';
                            });
                          }
                        },
                      ),
                      ChoiceChip(
                        label: Text('Today'),
                        selected: _filters['availability'] == 'today',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _filters['availability'] = 'today';
                            });
                          }
                        },
                      ),
                      ChoiceChip(
                        label: Text('This Week'),
                        selected: _filters['availability'] == 'week',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _filters['availability'] = 'week';
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  CheckboxListTile(
                    title: Text(
                      'Verified Artisans Only',
                      style: theme.textTheme.bodyMedium,
                    ),
                    value: _filters['verifiedOnly'] as bool,
                    onChanged: (value) {
                      setState(() {
                        _filters['verifiedOnly'] = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  SizedBox(height: 2.h),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApplyFilters(_filters);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 6.h),
                ),
                child: Text('Apply Filters'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
