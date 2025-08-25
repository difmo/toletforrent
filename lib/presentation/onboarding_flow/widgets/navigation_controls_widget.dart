import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class NavigationControlsWidget extends StatelessWidget {
  final bool isLastPage;
  final VoidCallback? onNext;
  final VoidCallback? onSkip;

  const NavigationControlsWidget({
    super.key,
    required this.isLastPage,
    this.onNext,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    if (isLastPage) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.6),
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            ),
            child: Text(
              'Skip',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.lightTheme.colorScheme.onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: onNext,
              icon: CustomIconWidget(
                iconName: 'arrow_forward',
                color: AppTheme.lightTheme.colorScheme.onPrimary,
                size: 24,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
                padding: EdgeInsets.all(3.w),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
