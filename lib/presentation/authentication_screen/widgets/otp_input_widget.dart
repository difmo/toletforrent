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
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  late final AnimationController _timerController =
      AnimationController(duration: const Duration(seconds: 30), vsync: this)
        ..forward();
  late final Animation<double> _timerAnimation =
      Tween<double>(begin: 1.0, end: 0.0).animate(_timerController);

  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    // Repaint borders on focus change
    for (final n in _focusNodes) {
      n.addListener(() => setState(() {}));
    }
    _timerController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _canResend = true);
      }
    });
  }

  @override
  void dispose() {
    _timerController.dispose();
    for (final c in _controllers) c.dispose();
    for (final n in _focusNodes) n.dispose();
    super.dispose();
  }

  void _resetTimer() {
    setState(() => _canResend = false);
    _timerController
      ..reset()
      ..forward();
  }

  void _updateOtp() {
    final otp = _controllers.map((c) => c.text).join();
    widget.onOtpChanged(otp);
  }

  void _pasteOtp(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    for (int i = 0; i < 6; i++) {
      _controllers[i].text = i < digits.length ? digits[i] : '';
    }
    final lastIndex =
        digits.isEmpty ? 0 : (digits.length - 1).clamp(0, 5).toInt();
    _focusNodes[lastIndex].requestFocus();
    _updateOtp();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.lightTheme.colorScheme;

    return Column(
      children: [
        // Header
        Text(
          'Enter Verification Code',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'We sent a 6-digit code to ${widget.phoneNumber}',
          style: GoogleFonts.roboto(
            fontSize: 12.sp,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 4.h),

        // OTP Inputs (responsive)
        LayoutBuilder(
          builder: (context, constraints) {
            final double maxW = constraints.maxWidth;

            // Spacing and size rules
            const double gap = 10; // horizontal/vertical gap in dp
            const double minBox = 48; // accessible minimum tap target
            const double maxBox = 64; // comfortable maximum size

            // Pick columns so boxes never shrink below minBox
            int columns = 6;
            while (columns > 3) {
              final double candidate = (maxW - gap * (columns - 1)) / columns;
              if (candidate >= minBox) break;
              columns--;
            }

            final double boxW =
                ((maxW - gap * (columns - 1)) / columns).clamp(minBox, maxBox);
            final double boxH = boxW * 1.2; // a bit taller than wide

            return AutofillGroup(
              child: Wrap(
                spacing: gap,
                runSpacing: gap,
                alignment: WrapAlignment.center,
                children: List.generate(
                  6,
                  (i) => _buildOtpField(
                    index: i,
                    width: boxW,
                    height: boxH,
                    // Autofill only really needs to be on one field
                    autofill: i == 0,
                    colorScheme: colorScheme,
                  ),
                ),
              ),
            );
          },
        ),
        SizedBox(height: 4.h),

        // Resend / Timer
        AnimatedBuilder(
          animation: _timerAnimation,
          builder: (context, _) {
            final remaining = (_timerAnimation.value * 30).ceil();
            return Column(
              children: [
                if (!_canResend) ...[
                  Text(
                    'Resend code in ${remaining}s',
                    style: GoogleFonts.roboto(
                      fontSize: 10.sp,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  SizedBox(height: 1.h),
                  LinearProgressIndicator(
                    value: 1.0 - _timerAnimation.value,
                    backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(colorScheme.primary),
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
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                        color: widget.isLoading
                            ? colorScheme.onSurface.withValues(alpha: 0.4)
                            : colorScheme.primary,
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

  Widget _buildOtpField({
    required int index,
    required double width,
    required double height,
    required bool autofill,
    required ColorScheme colorScheme,
  }) {
    final hasFocus = _focusNodes[index].hasFocus;

    return SizedBox(
      width: width,
      height: height,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        autofocus: index == 0,
        textInputAction:
            index == 5 ? TextInputAction.done : TextInputAction.next,
        enableSuggestions: false,
        autocorrect: false,
        autofillHints: autofill ? const [AutofillHints.oneTimeCode] : null,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
          isCollapsed: true,
          contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 0),
        ),
        style: GoogleFonts.roboto(
          fontSize: (height * 0.45).clamp(14.0, 22.0), // scales with box
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
        onChanged: (value) {
          // Handle paste (multiple chars)
          if (value.length > 1) {
            _pasteOtp(value);
            return;
          }

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
        onFieldSubmitted: (_) {
          if (index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else {
            _focusNodes[index].unfocus();
          }
        },
      ),
    );
  }
}
