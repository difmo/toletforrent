import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import './widgets/animated_logo_widget.dart';
import './widgets/loading_indicator_widget.dart';
import './widgets/retry_widget.dart';
import './widgets/tagline_widget.dart';

/// Splash Screen providing branded app launch experience while initializing core services
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  bool _showTagline = false;
  bool _showLoading = false;
  bool _showRetry = false;
  bool _isInitializing = false;

  // resolved at runtime
  bool _isAuthenticated = false;
  bool _isFirstTime = true;
  String? _storedDeepLink;

  @override
  void initState() {
    super.initState();
    _setSystemUIOverlay();
    _handleDeepLink();
    _startInitialization();
  }

  void _setSystemUIOverlay() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: AppTheme.lightTheme.colorScheme.primary,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppTheme.lightTheme.colorScheme.primary,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  void _handleDeepLink() {
    // TODO: plug real deep link handler; keeping a sample for now.
    final Uri? deepLink = Uri.tryParse('/property-detail-screen?id=prop_001');
    if (deepLink != null) _storedDeepLink = deepLink.toString();
  }

  Future<void> _startInitialization() async {
    if (_isInitializing) return;
    setState(() {
      _isInitializing = true;
      _showRetry = false;
    });

    try {
      // Start logo animation
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() => _showTagline = true);

      // Show loading indicator
      await Future.delayed(const Duration(milliseconds: 800));
      setState(() => _showLoading = true);

      // Perform real checks (auth + first run)
      await _performInitializationTasks();

      await Future.delayed(const Duration(milliseconds: 500));
      _navigateToNextScreen();
    } catch (_) {
      // Show retry after a small delay
      await Future.delayed(const Duration(seconds: 5));
      if (!mounted) return;
      setState(() {
        _showLoading = false;
        _showRetry = true;
        _isInitializing = false;
      });
    }
  }

  Future<void> _performInitializationTasks() async {
    // 1) First-run flag (SharedPreferences)
    final prefs = await SharedPreferences.getInstance();
    _isFirstTime = !(prefs.getBool('onboarded') ?? false);

    // 2) Auth status
    final auth = FirebaseAuth.instance;

    // Use currentUser if available immediately
    User? u = auth.currentUser;

    // If null, wait briefly for the first auth event (helpful right after app install)
    if (u == null) {
      try {
        u = await auth.authStateChanges().first.timeout(
              const Duration(seconds: 2),
              onTimeout: () => null,
            );
      } catch (_) {
        // ignore and treat as signed out
      }
    }

    _isAuthenticated = u != null;

    // (Optional) preload anything else here: feature flags, remote config, etc.
    await Future.delayed(const Duration(milliseconds: 300));
  }

  void _navigateToNextScreen() {
    if (!mounted) return;

    String nextRoute;

    if (_isFirstTime) {
      nextRoute = '/onboarding-flow';
    } else if (_isAuthenticated) {
      nextRoute = _storedDeepLink ?? '/home-screen';
    } else {
      nextRoute = '/authentication-screen';
    }

    // Ensure navigation happens after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, nextRoute);
      }
    });
  }

  void _handleRetry() {
    setState(() => _showRetry = false);
    _startInitialization();
  }

  void _onLogoAnimationComplete() {
    // hook if you want
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.lightTheme.colorScheme.primary,
              AppTheme.lightTheme.colorScheme.primaryContainer,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated Logo
                      AnimatedLogoWidget(
                        onAnimationComplete: _onLogoAnimationComplete,
                      ),
                      SizedBox(height: 4.h),
                      // Tagline
                      TaglineWidget(isVisible: _showTagline),
                    ],
                  ),
                ),
              ),
              // Bottom section with loading/retry
              SizedBox(
                height: 20.h,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!_showRetry)
                      LoadingIndicatorWidget(isVisible: _showLoading),
                    if (_showRetry)
                      RetryWidget(
                        isVisible: _showRetry,
                        onRetry: _handleRetry,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Reset system UI overlay
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    super.dispose();
  }
}
