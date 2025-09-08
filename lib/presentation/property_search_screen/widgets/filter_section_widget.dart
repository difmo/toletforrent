import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class FilterSectionWidget extends StatefulWidget {
  final RangeValues priceRange;
  final List<String> selectedBHK;
  final List<String> selectedPropertyTypes;
  final List<String> selectedFurnishedStatus;
  final ValueChanged<RangeValues> onPriceRangeChanged;
  final ValueChanged<List<String>> onBHKChanged;
  final ValueChanged<List<String>> onPropertyTypesChanged;
  final ValueChanged<List<String>> onFurnishedStatusChanged;
  final VoidCallback onMoreFiltersPressed;
  final VoidCallback onClearAllPressed;

  const FilterSectionWidget({
    super.key,
    required this.priceRange,
    required this.selectedBHK,
    required this.selectedPropertyTypes,
    required this.selectedFurnishedStatus,
    required this.onPriceRangeChanged,
    required this.onBHKChanged,
    required this.onPropertyTypesChanged,
    required this.onFurnishedStatusChanged,
    required this.onMoreFiltersPressed,
    required this.onClearAllPressed,
  });

  @override
  State<FilterSectionWidget> createState() => _FilterSectionWidgetState();
}

class _FilterSectionWidgetState extends State<FilterSectionWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.shadowColor.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          
          children: [
            _buildFilterHeader(),
            if (_isExpanded) ...[
              _buildPriceRangeFilter(),
              _buildBHKFilter(),
              _buildPropertyTypeFilter(),
              _buildFurnishedStatusFilter(),
              _buildMoreFiltersButton(),
              SizedBox(height: 2.h),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterHeader() {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'tune',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 24,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Filters',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 2.w),
                if (_getActiveFilterCount() > 0)
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_getActiveFilterCount()}',
                      style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            Row(
              children: [
                if (_getActiveFilterCount() > 0)
                  GestureDetector(
                    onTap: widget.onClearAllPressed,
                    child: Text(
                      'Clear All',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                SizedBox(width: 2.w),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: CustomIconWidget(
                    iconName: 'keyboard_arrow_down',
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                    size: 24,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRangeFilter() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price Range',
            style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${(widget.priceRange.start / 1000).toInt()}K',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '₹${(widget.priceRange.end / 1000).toInt()}K',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          RangeSlider(
            values: widget.priceRange,
            min: 5000,
            max: 100000,
            divisions: 19,
            onChanged: widget.onPriceRangeChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildBHKFilter() {
    final bhkOptions = ['1 BHK', '2 BHK', '3 BHK', '4+ BHK'];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BHK Configuration',
            style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: bhkOptions.map((bhk) {
              final isSelected = widget.selectedBHK.contains(bhk);
              return GestureDetector(
                onTap: () {
                  final updatedList = List<String>.from(widget.selectedBHK);
                  if (isSelected) {
                    updatedList.remove(bhk);
                  } else {
                    updatedList.add(bhk);
                  }
                  widget.onBHKChanged(updatedList);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.lightTheme.colorScheme.primary
                        : AppTheme.lightTheme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.lightTheme.colorScheme.primary
                          : AppTheme.lightTheme.dividerColor,
                    ),
                  ),
                  child: Text(
                    bhk,
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? AppTheme.lightTheme.colorScheme.onPrimary
                          : AppTheme.lightTheme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyTypeFilter() {
    final propertyTypes = ['Apartment', 'House', 'PG', 'Villa'];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Property Type',
            style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: propertyTypes.map((type) {
              final isSelected = widget.selectedPropertyTypes.contains(type);
              return GestureDetector(
                onTap: () {
                  final updatedList =
                      List<String>.from(widget.selectedPropertyTypes);
                  if (isSelected) {
                    updatedList.remove(type);
                  } else {
                    updatedList.add(type);
                  }
                  widget.onPropertyTypesChanged(updatedList);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.lightTheme.colorScheme.secondary
                            .withValues(alpha: 0.1)
                        : AppTheme.lightTheme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.lightTheme.colorScheme.secondary
                          : AppTheme.lightTheme.dividerColor,
                    ),
                  ),
                  child: Text(
                    type,
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? AppTheme.lightTheme.colorScheme.secondary
                          : AppTheme.lightTheme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFurnishedStatusFilter() {
    final furnishedOptions = [
      'Fully Furnished',
      'Semi Furnished',
      'Unfurnished'
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Furnished Status',
            style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: furnishedOptions.map((status) {
              final isSelected =
                  widget.selectedFurnishedStatus.contains(status);
              return GestureDetector(
                onTap: () {
                  final updatedList =
                      List<String>.from(widget.selectedFurnishedStatus);
                  if (isSelected) {
                    updatedList.remove(status);
                  } else {
                    updatedList.add(status);
                  }
                  widget.onFurnishedStatusChanged(updatedList);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.lightTheme.colorScheme.tertiary
                            .withValues(alpha: 0.1)
                        : AppTheme.lightTheme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.lightTheme.colorScheme.tertiary
                          : AppTheme.lightTheme.dividerColor,
                    ),
                  ),
                  child: Text(
                    status,
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? AppTheme.lightTheme.colorScheme.tertiary
                          : AppTheme.lightTheme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreFiltersButton() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: GestureDetector(
        onTap: widget.onMoreFiltersPressed,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 1.h),
          decoration: BoxDecoration(
            color:
                AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.lightTheme.colorScheme.primary
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomIconWidget(
                iconName: 'add',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 12,
              ),
              SizedBox(width: 2.w),
              Text(
                'More Filters',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 12
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (widget.priceRange.start > 1000 || widget.priceRange.end < 100000)
      count++;
    if (widget.selectedBHK.isNotEmpty) count++;
    if (widget.selectedPropertyTypes.isNotEmpty) count++;
    if (widget.selectedFurnishedStatus.isNotEmpty) count++;
    return count;
  }
}
