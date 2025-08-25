import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import './widgets/email_input_widget.dart';
import './widgets/otp_input_widget.dart';
import './widgets/phone_input_widget.dart';
import './widgets/social_login_widget.dart';

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

  // Mock credentials for testing
  final Map<String, String> _mockCredentials = {
    'phone': '+919876543210',
    'email': 'user@toletforrent.com',
    'password': 'password123',
    'otp': '123456',
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
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
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

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
                fontSize: 14.sp,
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
          SizedBox(height: 6.h),
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
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.lightTheme.colorScheme.primary
                    .withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: CustomIconWidget(
              iconName: 'home',
              size: 32,
              color: AppTheme.lightTheme.colorScheme.onPrimary,
            ),
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'ToLetForRent',
          style: GoogleFonts.inter(
            fontSize: 24.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          'Find Your Perfect Home',
          style: GoogleFonts.roboto(
            fontSize: 14.sp,
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
            fontSize: 28.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Enter your phone number to continue',
          style: GoogleFonts.roboto(
            fontSize: 16.sp,
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
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handlePhoneSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.lightTheme.colorScheme.primary,
          foregroundColor: AppTheme.lightTheme.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
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
                'Continue',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildVerifyButton() {
    return SizedBox(
      width: double.infinity,
      height: 6.h,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleOtpVerification,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.lightTheme.colorScheme.primary,
          foregroundColor: AppTheme.lightTheme.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
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
                'Verify & Continue',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
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
            fontSize: 14.sp,
            color: AppTheme.lightTheme.colorScheme.onSurface
                .withValues(alpha: 0.7),
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() => _currentStep = AuthenticationStep.emailAuth);
            _pageController.animateToPage(
              2,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          child: Text(
            'Sign in with Email',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: AppTheme.lightTheme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  // Event Handlers
  void _handlePhoneSubmit() {
    if (_phoneController.text.isEmpty) {
      setState(() => _phoneError = 'Phone number is required');
      return;
    }
    if (_phoneController.text.length < 10) {
      setState(() => _phoneError = 'Please enter a valid phone number');
      return;
    }

    setState(() => _isLoading = true);

    // Simulate API call
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentStep = AuthenticationStep.otpVerification;
        });
        _pageController.animateToPage(
          1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _handleOtpChanged(String otp) {
    if (otp.length == 6) {
      _handleOtpVerification();
    }
  }

  void _handleOtpVerification() {
    setState(() => _isLoading = true);

    // Simulate OTP verification
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isLoading = false);
        _navigateToHome();
      }
    });
  }

  void _handleResendOtp() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('OTP sent to $_fullPhoneNumber'),
        backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
      ),
    );
  }

  void _handleGoogleSignIn() {
    setState(() => _isLoading = true);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isLoading = false);
        _navigateToHome();
      }
    });
  }

  void _handleAppleSignIn() {
    setState(() => _isLoading = true);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isLoading = false);
        _navigateToHome();
      }
    });
  }

  void _handleEmailSignIn(String email, String password) {
    if (email != _mockCredentials['email'] ||
        password != _mockCredentials['password']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Invalid credentials. Use ${_mockCredentials['email']} / ${_mockCredentials['password']}'),
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isLoading = false);
        _navigateToHome();
      }
    });
  }

  void _handleEmailSignUp(String email, String password) {
    setState(() => _isLoading = true);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isLoading = false);
        _navigateToHome();
      }
    });
  }

  void _handleBackNavigation() {
    switch (_currentStep) {
      case AuthenticationStep.otpVerification:
        setState(() => _currentStep = AuthenticationStep.phoneInput);
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        break;
      case AuthenticationStep.emailAuth:
        setState(() => _currentStep = AuthenticationStep.phoneInput);
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
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