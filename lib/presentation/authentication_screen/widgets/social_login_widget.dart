import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';

class SocialLoginWidget extends StatelessWidget {
  final VoidCallback onGoogleSignIn;
  final VoidCallback onAppleSignIn;
  final bool showAppleSignIn;

  const SocialLoginWidget({
    super.key,
    required this.onGoogleSignIn,
    required this.onAppleSignIn,
    this.showAppleSignIn = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Divider with "OR" text
        Row(
          children: [
            Expanded(
              child: Divider(
                color: AppTheme.lightTheme.dividerColor,
                thickness: 1,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                'OR',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.lightTheme.colorScheme.onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: AppTheme.lightTheme.dividerColor,
                thickness: 1,
              ),
            ),
          ],
        ),
        SizedBox(height: 3.h),

        // Google Sign In Button
        _buildSocialButton(
          onTap: onGoogleSignIn,
          icon: 'g_logo',
          text: 'Continue with Google',
          backgroundColor: AppTheme.lightTheme.colorScheme.surface,
          textColor: AppTheme.lightTheme.colorScheme.onSurface,
          borderColor: AppTheme.lightTheme.dividerColor,
        ),

        // Apple Sign In Button (iOS only)
        if (showAppleSignIn) ...[
          SizedBox(height: 2.h),
          _buildSocialButton(
            onTap: onAppleSignIn,
            icon: 'apple',
            text: 'Continue with Apple',
            backgroundColor: Colors.black,
            textColor: Colors.white,
            borderColor: Colors.black,
          ),
        ],
      ],
    );
  }

  Widget _buildSocialButton({
    required VoidCallback onTap,
    required String icon,
    required String text,
    required Color backgroundColor,
    required Color textColor,
    required Color borderColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 6.h,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialIcon(icon),
            SizedBox(width: 3.w),
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialIcon(String iconType) {
    switch (iconType) {
      case 'g_logo':
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              'G',
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue[600],
              ),
            ),
          ),
        );
      case 'apple':
        return CustomIconWidget(
          iconName: 'apple',
          size: 24,
          color: Colors.white,
        );
      default:
        return CustomIconWidget(
          iconName: 'login',
          size: 24,
          color: AppTheme.lightTheme.colorScheme.primary,
        );
    }
  }
}