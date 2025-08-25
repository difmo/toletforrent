import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class DraftSaveWidget extends StatelessWidget {
  final VoidCallback onSave;
  final bool isLoading;

  const DraftSaveWidget({
    super.key,
    required this.onSave,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 2.w),
      child: GestureDetector(
        onTap: isLoading ? null : onSave,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.secondary
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.lightTheme.colorScheme.secondary
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.lightTheme.colorScheme.secondary,
                    ),
                  ),
                )
              else
                CustomIconWidget(
                  iconName: 'save',
                  color: AppTheme.lightTheme.colorScheme.secondary,
                  size: 16,
                ),
              SizedBox(width: 1.w),
              Text(
                isLoading ? 'Saving...' : 'Save Draft',
                style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
