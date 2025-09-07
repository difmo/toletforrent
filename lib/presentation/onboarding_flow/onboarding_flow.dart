import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import './widgets/navigation_controls_widget.dart';
import './widgets/onboarding_page_widget.dart';
import './widgets/page_indicator_widget.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _onboardingData = [
    {
      "title": "Find Your Perfect Home",
      "subtitle":
          "Discover thousands of verified rental properties across India. From cozy studios to spacious family homes, find exactly what you're looking for.",
      "imageUrl":
          "https://images.unsplash.com/photo-1560518883-ce09059eeffa?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8aG91c2V8ZW58MHx8MHx8fDA%3D",
    },
    {
      "title": "Verified & Trusted Listings",
      "subtitle":
          "Every property is verified by our team. Connect directly with verified property owners and agents for authentic rental experiences.",
      "imageUrl":
          "https://images.unsplash.com/photo-1582407947304-fd86f028f716?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8dmVyaWZpZWR8ZW58MHx8MHx8fDA%3D",
    },
    {
      "title": "Direct Owner Contact",
      "subtitle":
          "Skip the middleman and connect directly with property owners. Chat, call, or schedule visits seamlessly through our secure platform.",
      "imageUrl":
          "https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8M3x8Y29udGFjdHxlbnwwfHwwfHx8MA%3D%3D",
    },
    {
      "title": "Secure & Hassle-Free",
      "subtitle":
          "Experience secure transactions with digital agreements, verified payments, and 24/7 support. Your dream home is just a tap away!",
      "imageUrl":
          "https://images.unsplash.com/photo-1563013544-824ae1b704d3?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8c2VjdXJlfGVufDB8fDB8fHww",
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipOnboarding() {
    _completeOnboarding('/authentication-screen');
  }

  void _getStarted() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _completeOnboarding('/home-screen');
    } else {
      _completeOnboarding('/authentication-screen');
    }
  }

  void _signIn() {
    _completeOnboarding('/authentication-screen');
  }

  Future<void> _completeOnboarding(String nextRoute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarded', true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, nextRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _onboardingData.length,
              itemBuilder: (context, index) {
                final data = _onboardingData[index];
                return OnboardingPageWidget(
                  title: data["title"] as String,
                  subtitle: data["subtitle"] as String,
                  imageUrl: data["imageUrl"] as String,
                  isLastPage: index == _onboardingData.length - 1,
                  onGetStarted: _getStarted,
                  onSignIn: _signIn,
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(vertical: 2.h),
            child: PageIndicatorWidget(
              currentPage: _currentPage,
              totalPages: _onboardingData.length,
            ),
          ),
          NavigationControlsWidget(
            isLastPage: _currentPage == _onboardingData.length - 1,
            onNext: _nextPage,
            onSkip: _skipOnboarding,
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }
}
