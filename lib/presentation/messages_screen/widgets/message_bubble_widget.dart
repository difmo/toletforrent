import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class MessageBubbleWidget extends StatelessWidget {
  final Map<String, dynamic> message;

  const MessageBubbleWidget({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSender = message['isSender'] ?? false;

    return Container(
      margin: EdgeInsets.only(
        bottom: 1.h,
        left: isSender ? 10.w : 0,
        right: isSender ? 0 : 10.w,
      ),
      child: Column(
        crossAxisAlignment:
            isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Message bubble
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 4.w,
              vertical: 2.h,
            ),
            decoration: BoxDecoration(
              color: isSender
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isSender ? 16 : 4),
                bottomRight: Radius.circular(isSender ? 4 : 16),
              ),
              border: isSender
                  ? null
                  : Border.all(
                      color: AppTheme.lightTheme.dividerColor
                          .withValues(alpha: 0.3),
                      width: 1,
                    ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message['message'],
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: isSender
                        ? AppTheme.lightTheme.colorScheme.onPrimary
                        : AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message['timestamp'],
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: isSender
                            ? AppTheme.lightTheme.colorScheme.onPrimary
                                .withValues(alpha: 0.8)
                            : AppTheme.lightTheme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                      ),
                    ),
                    if (isSender) ...[
                      SizedBox(width: 1.w),
                      CustomIconWidget(
                        iconName: _getStatusIcon(message['status']),
                        color: AppTheme.lightTheme.colorScheme.onPrimary
                            .withValues(alpha: 0.8),
                        size: 12,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusIcon(String? status) {
    switch (status) {
      case 'sent':
        return 'check';
      case 'delivered':
        return 'done_all';
      case 'read':
        return 'done_all';
      default:
        return 'schedule';
    }
  }
}
