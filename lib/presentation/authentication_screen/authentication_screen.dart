import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/app_export.dart';
import '../../data/services/auth_service.dart'; // ⬅️ add
import './widgets/email_input_widget.dart';
import './widgets/otp_input_widget.dart';
import './widgets/phone_input_widget.dart';
import './widgets/social_login_widget.dart';
import 'dart:io' show Platform;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final PageController _pageController = PageController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  AuthenticationStep _currentStep = AuthenticationStep.phoneInput;
  bool _isLoading = false;
  String? _phoneError;
  String _fullPhoneNumber = '';

  // 🔐 OTP state
  String? _verificationId;
  String _otpCode = '';
  StreamSubscription<User?>? _authSub;
  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    // already signed in? leave immediately
    final u = FirebaseAuth.instance.currentUser;
    if (u != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _routeHomeOnce());
    }

    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) _routeHomeOnce();
    });
  }

// inside _AuthenticationScreenState
  bool _didRoute = false;
  void _routeHomeOnce() {
    if (_didRoute || !mounted) return;
    _didRoute = true;
    Navigator.pushNamedAndRemoveUntil(context, '/home-screen', (_) => false);
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pageController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildPhoneInputPage(),
                      _buildOtpVerificationPage(),
                      _buildEmailAuthPage(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        children: [
          if (_currentStep != AuthenticationStep.phoneInput)
            GestureDetector(
              onTap: _handleBackNavigation,
              child: Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.lightTheme.dividerColor,
                    width: 1,
                  ),
                ),
                child: CustomIconWidget(
                  iconName: 'arrow_back_ios',
                  size: 20,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
            ),
          const Spacer(),
          TextButton(
            onPressed: _handleGuestAccess,
            child: Text(
              'Skip',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneInputPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 4.h),
          _buildLogo(),
          SizedBox(height: 1.h),
          _buildWelcomeText(),
          SizedBox(height: 4.h),
          PhoneInputWidget(
            phoneController: _phoneController,
            onPhoneChanged: (phone) {
              setState(() {
                _fullPhoneNumber = phone;
                _phoneError = null;
              });
            },
            errorText: _phoneError,
          ),
          SizedBox(height: 4.h),
          _buildContinueButton(),
          SizedBox(height: 4.h),
          SocialLoginWidget(
            onGoogleSignIn: _handleGoogleSignIn,
            onAppleSignIn: _handleAppleSignIn,
            showAppleSignIn: defaultTargetPlatform == TargetPlatform.iOS,
          ),
          SizedBox(height: 3.h),
          _buildEmailSignInLink(),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildOtpVerificationPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      child: Column(
        children: [
          SizedBox(height: 8.h),
          OtpInputWidget(
            onOtpChanged: _handleOtpChanged,
            onResendOtp: _handleResendOtp,
            phoneNumber: _fullPhoneNumber,
            isLoading: _isLoading,
          ),
          SizedBox(height: 6.h),
          _buildVerifyButton(),
        ],
      ),
    );
  }

  Widget _buildEmailAuthPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      child: Column(
        children: [
          SizedBox(height: 4.h),
          _buildLogo(),
          SizedBox(height: 4.h),
          EmailInputWidget(
            emailController: _emailController,
            passwordController: _passwordController,
            onEmailSignIn: _handleEmailSignIn,
            onEmailSignUp: _handleEmailSignUp,
            isLoading: _isLoading,
          ),
          SizedBox(height: 4.h),
          SocialLoginWidget(
            onGoogleSignIn: _handleGoogleSignIn,
            onAppleSignIn: _handleAppleSignIn,
            showAppleSignIn: defaultTargetPlatform == TargetPlatform.iOS,
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 20.w,
          height: 10.h,
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.lightTheme.colorScheme.primary,
                AppTheme.lightTheme.colorScheme.secondary,
                AppTheme.lightTheme.colorScheme.tertiary ?? Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color:
                    AppTheme.lightTheme.colorScheme.primary.withOpacity(0.25),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color:
                    AppTheme.lightTheme.colorScheme.secondary.withOpacity(0.12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: SvgPicture.asset(
              'assets/images/logo.svg',
              width: 12.w,
              height: 12.w,
              color: AppTheme.lightTheme.colorScheme.onPrimary,
            ),
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'To-Let For Rent',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          'Find Your Perfect Home',
          style: GoogleFonts.roboto(
            fontSize: 12.sp,
            color: AppTheme.lightTheme.colorScheme.onSurface
                .withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      children: [
        Text(
          'Welcome Back!',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Enter your phone number to continue',
          style: GoogleFonts.roboto(
            fontSize: 12.sp,
            color: AppTheme.lightTheme.colorScheme.onSurface
                .withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      height: 6.h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.lightTheme.colorScheme.primary,
              AppTheme.lightTheme.colorScheme.secondary,
              AppTheme.lightTheme.colorScheme.tertiary ?? Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handlePhoneSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: AppTheme.lightTheme.colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.zero,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  'Continue',
                  style: GoogleFonts.inter(
                      fontSize: 12.sp, fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }

  Widget _buildVerifyButton() {
    return SizedBox(
      width: double.infinity,
      height: 6.h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.lightTheme.colorScheme.primary,
              AppTheme.lightTheme.colorScheme.secondary,
              AppTheme.lightTheme.colorScheme.tertiary ?? Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleOtpVerification,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: AppTheme.lightTheme.colorScheme.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: EdgeInsets.zero,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  'Verify & Continue',
                  style: GoogleFonts.inter(
                      fontSize: 12.sp, fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }

  Widget _buildEmailSignInLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Prefer email? ',
          style: GoogleFonts.roboto(
            fontSize: 12.sp,
            color: AppTheme.lightTheme.colorScheme.onSurface
                .withValues(alpha: 0.7),
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() => _currentStep = AuthenticationStep.emailAuth);
            _pageController.animateToPage(2,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut);
          },
          child: Text(
            'Sign in with Email',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: AppTheme.lightTheme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // Event Handlers  🔽 (real Firebase logic)
  // ----------------------------------------------------------

  Future<void> _handlePhoneSubmit() async {
    // Basic validation
    final raw = _phoneController.text.trim();
    if (raw.isEmpty) {
      setState(() => _phoneError = 'Phone number is required');
      return;
    }
    // Normalize to E.164 (+91… fallback for 10 digits)
    String phone = raw;
    if (!phone.startsWith('+')) {
      if (phone.length == 10) {
        phone = '+91$phone';
      } else {
        setState(
            () => _phoneError = 'Enter number like +9198XXXXXXXX or 10 digits');
        return;
      }
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _phoneError = null;
      _fullPhoneNumber = phone;
    });

    try {
      // You can also call FirebaseAuth.verifyPhoneNumber if you need resend tokens.
      _verificationId = await AuthService.I.sendOtp(e164Phone: phone);
      setState(() {
        _isLoading = false;
        _currentStep = AuthenticationStep.otpVerification;
      });
      _pageController.animateToPage(1,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP sent to $phone')),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Failed to send OTP')),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send OTP: $e')),
      );
    }
  }

  void _handleOtpChanged(String otp) {
    _otpCode = otp;
    if (otp.length == 6) {
      _handleOtpVerification();
    }
  }

  Future<void> _handleOtpVerification() async {
    if ((_verificationId ?? '').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No verification in progress')));
      return;
    }
    if (_otpCode.length != 6) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter 6-digit OTP')));
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      await AuthService.I.verifyOtpAndSignIn(
        verificationId: _verificationId!,
        smsCode: _otpCode,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      _navigateToHome();
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'OTP verification failed')),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP verification failed: $e')),
      );
    }
  }

  Future<void> _handleResendOtp() async {
    if (_fullPhoneNumber.isEmpty) return;
    try {
      setState(() => _isLoading = true);
      _verificationId =
          await AuthService.I.sendOtp(e164Phone: _fullPhoneNumber);
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP re-sent to $_fullPhoneNumber')),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not resend OTP: $e')),
      );
    }
  }

  bool _googleInFlight = false;

  Future<void> _handleGoogleSignIn() async {
    if (_googleInFlight) return;
    if (FirebaseAuth.instance.currentUser != null) {
      _routeHomeOnce();
      return;
    }

    _googleInFlight = true;
    setState(() => _isLoading = true);
    try {
      final provider =
          GoogleAuthProvider(); // no custom prompt -> avoids re-chooser
      if (kIsWeb) {
        await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        await FirebaseAuth.instance.signInWithProvider(provider);
      }

      // Sign-in is done; route now (in case the stream is late).
      if (mounted) _routeHomeOnce();
    } on FirebaseAuthException catch (e) {
      const benign = {
        'web-context-canceled',
        'popup-closed-by-user',
        'user-cancelled'
      };
      if (!benign.contains(e.code)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Google sign-in failed (${e.code}): ${e.message ?? ''}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign-in failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
      _googleInFlight = false;
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Apple Sign-In not implemented yet')),
    );
  }

  Future<void> _handleEmailSignIn(String email, String password) async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    try {
      await AuthService.I.signInWithEmail(email, password);
      if (!mounted) return;
      setState(() => _isLoading = false);
      _navigateToHome();
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Email sign-in failed')),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email sign-in failed: $e')),
      );
    }
  }

  Future<void> _handleEmailSignUp(String email, String password) async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    try {
      await AuthService.I.signUpWithEmail(email, password);
      if (!mounted) return;
      setState(() => _isLoading = false);
      _navigateToHome();
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Email sign-up failed')),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email sign-up failed: $e')),
      );
    }
  }

  void _handleBackNavigation() {
    switch (_currentStep) {
      case AuthenticationStep.otpVerification:
        setState(() => _currentStep = AuthenticationStep.phoneInput);
        _pageController.animateToPage(0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut);
        break;
      case AuthenticationStep.emailAuth:
        setState(() => _currentStep = AuthenticationStep.phoneInput);
        _pageController.animateToPage(0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut);
        break;
      default:
        Navigator.pop(context);
    }
  }

  void _handleGuestAccess() {
    _navigateToHome();
  }

  void _navigateToHome() {
    Navigator.pushReplacementNamed(context, '/home-screen');
  }
}

enum AuthenticationStep {
  phoneInput,
  otpVerification,
  emailAuth,
}
