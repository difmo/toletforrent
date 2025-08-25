import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ActiveFiltersWidget extends StatelessWidget {
  final RangeValues priceRange;
  final List<String> selectedBHK;
  final List<String> selectedPropertyTypes;
  final List<String> selectedFurnishedStatus;
  final ValueChanged<String> onRemoveFilter;
  final VoidCallback onClearAll;

  const ActiveFiltersWidget({
    super.key,
    required this.priceRange,
    required this.selectedBHK,
    required this.selectedPropertyTypes,
    required this.selectedFurnishedStatus,
    required this.onRemoveFilter,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final activeFilters = _getActiveFilters();

    if (activeFilters.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.lightTheme.dividerColor.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Filters',
                style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: onClearAll,
                child: Text(
                  'Clear All',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: activeFilters
                .map((filter) => _buildFilterChip(filter))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(Map<String, String> filter) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            filter['label']!,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 2.w),
          GestureDetector(
            onTap: () => onRemoveFilter(filter['key']!),
            child: Container(
              padding: EdgeInsets.all(0.5.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary
                    .withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: CustomIconWidget(
                iconName: 'close',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, String>> _getActiveFilters() {
    final filters = <Map<String, String>>[];

    // Price range filter
    if (priceRange.start > 5000 || priceRange.end < 100000) {
      filters.add({
        'key': 'price',
        'label':
            '₹${(priceRange.start / 1000).toInt()}K - ₹${(priceRange.end / 1000).toInt()}K',
      });
    }

    // BHK filters
    for (final bhk in selectedBHK) {
      filters.add({
        'key': 'bhk_$bhk',
        'label': bhk,
      });
    }

    // Property type filters
    for (final type in selectedPropertyTypes) {
      filters.add({
        'key': 'type_$type',
        'label': type,
      });
    }

    // Furnished status filters
    for (final status in selectedFurnishedStatus) {
      filters.add({
        'key': 'furnished_$status',
        'label': status,
      });
    }

    return filters;
  }
}
