import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';

class EmailInputWidget extends StatefulWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final Function(String, String) onEmailSignIn;
  final Function(String, String) onEmailSignUp;
  final bool isLoading;

  const EmailInputWidget({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.onEmailSignIn,
    required this.onEmailSignUp,
    this.isLoading = false,
  });

  @override
  State<EmailInputWidget> createState() => _EmailInputWidgetState();
}

class _EmailInputWidgetState extends State<EmailInputWidget> {
  bool _isPasswordVisible = false;
  bool _isSignUpMode = false;
  String? _emailError;
  String? _passwordError;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle between Sign In and Sign Up
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _isSignUpMode = false),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: !_isSignUpMode
                            ? AppTheme.lightTheme.colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    'Sign In',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight:
                          !_isSignUpMode ? FontWeight.w600 : FontWeight.w400,
                      color: !_isSignUpMode
                          ? AppTheme.lightTheme.colorScheme.primary
                          : AppTheme.lightTheme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _isSignUpMode = true),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: _isSignUpMode
                            ? AppTheme.lightTheme.colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    'Sign Up',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight:
                          _isSignUpMode ? FontWeight.w600 : FontWeight.w400,
                      color: _isSignUpMode
                          ? AppTheme.lightTheme.colorScheme.primary
                          : AppTheme.lightTheme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 3.h),

        // Email Input
        _buildInputField(
          label: 'Email Address',
          controller: widget.emailController,
          hintText: 'Enter your email',
          keyboardType: TextInputType.emailAddress,
          errorText: _emailError,
          prefixIcon: 'email',
        ),
        SizedBox(height: 2.h),

        // Password Input
        _buildInputField(
          label: 'Password',
          controller: widget.passwordController,
          hintText: 'Enter your password',
          isPassword: true,
          errorText: _passwordError,
          prefixIcon: 'lock',
          suffixIcon: GestureDetector(
            onTap: () =>
                setState(() => _isPasswordVisible = !_isPasswordVisible),
            child: CustomIconWidget(
              iconName: _isPasswordVisible ? 'visibility_off' : 'visibility',
              size: 20,
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.6),
            ),
          ),
        ),

        if (!_isSignUpMode) ...[
          SizedBox(height: 1.h),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // Handle forgot password
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Forgot password feature coming soon')),
                );
              },
              child: Text(
                'Forgot Password?',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
            ),
          ),
        ],

        SizedBox(height: 3.h),

        // Submit Button
        SizedBox(
          width: double.infinity,
          height: 6.h,
          child: ElevatedButton(
            onPressed: widget.isLoading ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.colorScheme.primary,
              foregroundColor: AppTheme.lightTheme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.lightTheme.colorScheme.onPrimary,
                      ),
                    ),
                  )
                : Text(
                    _isSignUpMode ? 'Create Account' : 'Sign In',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    String? errorText,
    String? prefixIcon,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: isPassword && !_isPasswordVisible,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.roboto(
              fontSize: 16.sp,
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.5),
            ),
            prefixIcon: prefixIcon != null
                ? Padding(
                    padding: EdgeInsets.all(3.w),
                    child: CustomIconWidget(
                      iconName: prefixIcon,
                      size: 20,
                      color: AppTheme.lightTheme.colorScheme.onSurface
                          .withValues(alpha: 0.6),
                    ),
                  )
                : null,
            suffixIcon: suffixIcon != null
                ? Padding(
                    padding: EdgeInsets.all(3.w),
                    child: suffixIcon,
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null
                    ? AppTheme.lightTheme.colorScheme.error
                    : AppTheme.lightTheme.dividerColor,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null
                    ? AppTheme.lightTheme.colorScheme.error
                    : AppTheme.lightTheme.dividerColor,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null
                    ? AppTheme.lightTheme.colorScheme.error
                    : AppTheme.lightTheme.colorScheme.primary,
                width: 2,
              ),
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          ),
          style: GoogleFonts.roboto(
            fontSize: 16.sp,
            fontWeight: FontWeight.w400,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        if (errorText != null) ...[
          SizedBox(height: 0.5.h),
          Text(
            errorText,
            style: GoogleFonts.roboto(
              fontSize: 12.sp,
              color: AppTheme.lightTheme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  void _handleSubmit() {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    // Validate email
    if (widget.emailController.text.isEmpty) {
      setState(() => _emailError = 'Email is required');
      return;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(widget.emailController.text)) {
      setState(() => _emailError = 'Please enter a valid email');
      return;
    }

    // Validate password
    if (widget.passwordController.text.isEmpty) {
      setState(() => _passwordError = 'Password is required');
      return;
    }
    if (widget.passwordController.text.length < 6) {
      setState(() => _passwordError = 'Password must be at least 6 characters');
      return;
    }

    // Submit
    if (_isSignUpMode) {
      widget.onEmailSignUp(
          widget.emailController.text, widget.passwordController.text);
    } else {
      widget.onEmailSignIn(
          widget.emailController.text, widget.passwordController.text);
    }
  }
}