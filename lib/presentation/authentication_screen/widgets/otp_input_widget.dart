import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class OtpInputWidget extends StatefulWidget {
  final Function(String) onOtpChanged;
  final Function() onResendOtp;
  final String phoneNumber;
  final bool isLoading;

  const OtpInputWidget({
    super.key,
    required this.onOtpChanged,
    required this.onResendOtp,
    required this.phoneNumber,
    this.isLoading = false,
  });

  @override
  State<OtpInputWidget> createState() => _OtpInputWidgetState();
}

class _OtpInputWidgetState extends State<OtpInputWidget>
    with TickerProviderStateMixin {
  final List<TextEditingController> _controllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  late AnimationController _timerController;
  late Animation<double> _timerAnimation;
  int _resendTimer = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    );
    _timerAnimation =
        Tween<double>(begin: 1.0, end: 0.0).animate(_timerController);
    _startTimer();
  }

  @override
  void dispose() {
    _timerController.dispose();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timerController.forward().then((_) {
      setState(() {
        _canResend = true;
      });
    });
  }

  void _resetTimer() {
    setState(() {
      _canResend = false;
      _resendTimer = 30;
    });
    _timerController.reset();
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Text(
          'Enter Verification Code',
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'We sent a 6-digit code to ${widget.phoneNumber}',
          style: GoogleFonts.roboto(
            fontSize: 14.sp,
            color: AppTheme.lightTheme.colorScheme.onSurface
                .withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 4.h),

        // OTP Input Fields
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (index) => _buildOtpField(index)),
        ),
        SizedBox(height: 4.h),

        // Resend Timer and Button
        AnimatedBuilder(
          animation: _timerAnimation,
          builder: (context, child) {
            final remainingTime = (_timerAnimation.value * 30).ceil();
            return Column(
              children: [
                if (!_canResend) ...[
                  Text(
                    'Resend code in ${remainingTime}s',
                    style: GoogleFonts.roboto(
                      fontSize: 14.sp,
                      color: AppTheme.lightTheme.colorScheme.onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                  SizedBox(height: 1.h),
                  LinearProgressIndicator(
                    value: 1.0 - _timerAnimation.value,
                    backgroundColor: AppTheme.lightTheme.colorScheme.primary
                        .withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.lightTheme.colorScheme.primary),
                  ),
                ] else ...[
                  TextButton(
                    onPressed: widget.isLoading
                        ? null
                        : () {
                            widget.onResendOtp();
                            _resetTimer();
                          },
                    child: Text(
                      'Resend Code',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: widget.isLoading
                            ? AppTheme.lightTheme.colorScheme.onSurface
                                .withValues(alpha: 0.4)
                            : AppTheme.lightTheme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildOtpField(int index) {
    return Container(
      width: 12.w,
      height: 6.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _focusNodes[index].hasFocus
              ? AppTheme.lightTheme.colorScheme.primary
              : AppTheme.lightTheme.dividerColor,
          width: _focusNodes[index].hasFocus ? 2 : 1.5,
        ),
      ),
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          border: InputBorder.none,
          counterText: '',
        ),
        style: GoogleFonts.roboto(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: AppTheme.lightTheme.colorScheme.onSurface,
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            if (index < 5) {
              _focusNodes[index + 1].requestFocus();
            } else {
              _focusNodes[index].unfocus();
            }
          } else {
            if (index > 0) {
              _focusNodes[index - 1].requestFocus();
            }
          }
          _updateOtp();
        },
        onTap: () {
          _controllers[index].selection = TextSelection.fromPosition(
            TextPosition(offset: _controllers[index].text.length),
          );
        },
      ),
    );
  }

  void _updateOtp() {
    String otp = _controllers.map((controller) => controller.text).join();
    widget.onOtpChanged(otp);
  }
}