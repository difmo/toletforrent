import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

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
  String? _storedDeepLink;

  // Mock user data for demonstration
  final Map<String, dynamic> _mockUserData = {
    "isAuthenticated": false,
    "isFirstTime": true,
    "userId": null,
    "userLocation": {
      "city": "Mumbai",
      "state": "Maharashtra",
      "coordinates": {"lat": 19.0760, "lng": 72.8777}
    },
    "preferences": {
      "propertyType": "apartment",
      "priceRange": {"min": 10000, "max": 50000},
      "bhkPreference": "2bhk"
    }
  };

  // Mock featured properties data
  final List<Map<String, dynamic>> _mockFeaturedProperties = [
    {
      "id": "prop_001",
      "title": "Spacious 2BHK in Bandra West",
      "price": "₹45,000",
      "location": "Bandra West, Mumbai",
      "image":
          "https://images.pexels.com/photos/1396122/pexels-photo-1396122.jpeg?auto=compress&cs=tinysrgb&w=800",
      "verified": true,
      "available": true,
      "bhk": "2BHK",
      "area": "850 sq ft"
    },
    {
      "id": "prop_002",
      "title": "Modern 3BHK with Sea View",
      "price": "₹75,000",
      "location": "Worli, Mumbai",
      "image":
          "https://images.pexels.com/photos/1571460/pexels-photo-1571460.jpeg?auto=compress&cs=tinysrgb&w=800",
      "verified": true,
      "available": true,
      "bhk": "3BHK",
      "area": "1200 sq ft"
    },
    {
      "id": "prop_003",
      "title": "Cozy 1BHK Near Metro Station",
      "price": "₹28,000",
      "location": "Andheri East, Mumbai",
      "image":
          "https://images.pexels.com/photos/1571468/pexels-photo-1571468.jpeg?auto=compress&cs=tinysrgb&w=800",
      "verified": false,
      "available": true,
      "bhk": "1BHK",
      "area": "600 sq ft"
    }
  ];

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
    // Simulate deep link handling
    final Uri? deepLink = Uri.tryParse('/property-detail-screen?id=prop_001');
    if (deepLink != null) {
      _storedDeepLink = deepLink.toString();
    }
  }

  void _startInitialization() async {
    if (_isInitializing) return;

    setState(() {
      _isInitializing = true;
      _showRetry = false;
    });

    try {
      // Start logo animation
      await Future.delayed(const Duration(milliseconds: 500));

      // Show tagline after logo animation starts
      setState(() {
        _showTagline = true;
      });

      // Show loading indicator
      await Future.delayed(const Duration(milliseconds: 800));
      setState(() {
        _showLoading = true;
      });

      // Perform initialization tasks
      await _performInitializationTasks();

      // Complete initialization
      await Future.delayed(const Duration(milliseconds: 500));
      _navigateToNextScreen();
    } catch (e) {
      // Show retry option after timeout
      await Future.delayed(const Duration(seconds: 5));
      if (mounted) {
        setState(() {
          _showLoading = false;
          _showRetry = true;
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _performInitializationTasks() async {
    // Simulate checking authentication status
    await Future.delayed(const Duration(milliseconds: 800));

    // Simulate loading user location preferences
    await Future.delayed(const Duration(milliseconds: 600));

    // Simulate fetching featured property data
    await Future.delayed(const Duration(milliseconds: 700));

    // Simulate preparing cached listings
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _navigateToNextScreen() {
    if (!mounted) return;

    final bool isAuthenticated = _mockUserData["isAuthenticated"] as bool;
    final bool isFirstTime = _mockUserData["isFirstTime"] as bool;

    String nextRoute;

    if (isFirstTime) {
      nextRoute = '/onboarding-flow';
    } else if (!isAuthenticated) {
      nextRoute = '/authentication-screen';
    } else {
      nextRoute = '/home-screen';
    }

    // Handle deep link if stored
    if (_storedDeepLink != null && isAuthenticated) {
      nextRoute = _storedDeepLink!;
    }

    Navigator.pushReplacementNamed(context, nextRoute);
  }

  void _handleRetry() {
    setState(() {
      _showRetry = false;
    });
    _startInitialization();
  }

  void _onLogoAnimationComplete() {
    // Logo animation completed, continue with initialization
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
                      TaglineWidget(
                        isVisible: _showTagline,
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom section with loading/retry
              Container(
                height: 20.h,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Loading Indicator
                    if (!_showRetry)
                      LoadingIndicatorWidget(
                        isVisible: _showLoading,
                      ),

                    // Retry Widget
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
