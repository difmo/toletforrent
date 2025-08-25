import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class ProgressIndicatorWidget extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepTitles;

  const ProgressIndicatorWidget({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepTitles,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.lightTheme.dividerColor.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          // Progress bar
          Row(
            children: List.generate(totalSteps, (index) {
              final isActive = index <= currentStep;
              final isCurrentStep = index == currentStep;

              return Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 1.w),
                  child: Column(
                    children: [
                      // Step circle
                      Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppTheme.lightTheme.colorScheme.primary
                              : AppTheme.lightTheme.colorScheme.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isActive
                                ? AppTheme.lightTheme.colorScheme.primary
                                : AppTheme.lightTheme.dividerColor,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: isActive
                              ? (index < currentStep
                                  ? Icon(
                                      Icons.check,
                                      size: 16,
                                      color: AppTheme
                                          .lightTheme.colorScheme.onPrimary,
                                    )
                                  : Text(
                                      '${index + 1}',
                                      style: AppTheme
                                          .lightTheme.textTheme.labelSmall
                                          ?.copyWith(
                                        color: AppTheme
                                            .lightTheme.colorScheme.onPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ))
                              : Text(
                                  '${index + 1}',
                                  style: AppTheme
                                      .lightTheme.textTheme.labelSmall
                                      ?.copyWith(
                                    color: AppTheme
                                        .lightTheme.colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: 1.h),
                      // Step title
                      Text(
                        stepTitles[index],
                        style:
                            AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                          color: isCurrentStep
                              ? AppTheme.lightTheme.colorScheme.primary
                              : isActive
                                  ? AppTheme.lightTheme.colorScheme.onSurface
                                  : AppTheme.lightTheme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                          fontWeight:
                              isCurrentStep ? FontWeight.w600 : FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 1.h),

          // Progress line
          Container(
            height: 2,
            margin: EdgeInsets.symmetric(horizontal: 8.w),
            child: LinearProgressIndicator(
              value: (currentStep + 1) / totalSteps,
              backgroundColor:
                  AppTheme.lightTheme.dividerColor.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
