import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SortOptionsWidget extends StatelessWidget {
  final String sortBy;
  final List<String> sortOptions;
  final String priceRange;
  final List<String> priceRanges;
  final ValueChanged<String> onSortChanged;
  final ValueChanged<String> onPriceRangeChanged;

  const SortOptionsWidget({
    super.key,
    required this.sortBy,
    required this.sortOptions,
    required this.priceRange,
    required this.priceRanges,
    required this.onSortChanged,
    required this.onPriceRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        children: [
          // Sort dropdown
          Expanded(
            flex: 3,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      AppTheme.lightTheme.dividerColor.withValues(alpha: 0.5),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: sortBy,
                  isExpanded: true,
                  items: sortOptions.map((option) {
                    return DropdownMenuItem(
                      value: option,
                      child: Row(
                        children: [
                          CustomIconWidget(
                            iconName: _getSortIcon(option),
                            size: 18,
                            color: AppTheme.lightTheme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            option,
                            style: AppTheme.lightTheme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) onSortChanged(value);
                  },
                ),
              ),
            ),
          ),

          SizedBox(width: 3.w),

          // Price range dropdown
          Expanded(
            flex: 2,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      AppTheme.lightTheme.dividerColor.withValues(alpha: 0.5),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: priceRange,
                  isExpanded: true,
                  items: priceRanges.map((range) {
                    return DropdownMenuItem(
                      value: range,
                      child: Text(
                        range,
                        style: AppTheme.lightTheme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) onPriceRangeChanged(value);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSortIcon(String sortOption) {
    switch (sortOption) {
      case 'Recently Added':
        return 'access_time';
      case 'Price Low-High':
        return 'trending_up';
      case 'Price High-Low':
        return 'trending_down';
      case 'Distance':
        return 'near_me';
      default:
        return 'sort';
    }
  }
}
