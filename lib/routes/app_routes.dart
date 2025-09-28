import 'package:flutter/material.dart';
import 'package:toletforrent/presentation/edit_profile/EditProfileScreen.dart';
import 'package:toletforrent/presentation/rent_payment/rent_payment_screen.dart';
import 'package:toletforrent/presentation/rental_history_screen/rental_history_screen.dart';
import 'package:toletforrent/presentation/visits_screens/MyVisitsScreen.dart';
import 'package:toletforrent/presentation/visits_screens/OwnerVisitsScreen.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/property_search_screen/property_search_screen.dart';
import '../presentation/authentication_screen/authentication_screen.dart';
import '../presentation/onboarding_flow/onboarding_flow.dart';
import '../presentation/home_screen/home_screen.dart';
import '../presentation/property_detail_screen/property_detail_screen.dart';
import '../presentation/favorites_screen/favorites_screen.dart';
import '../presentation/add_property_screen/add_property_screen.dart';
import '../presentation/messages_screen/messages_screen.dart';
import '../presentation/profile_screen/profile_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String splash = '/splash-screen';
  static const String propertySearch = '/property-search-screen';
  static const String authentication = '/authentication-screen';
  static const String onboardingFlow = '/onboarding-flow';
  static const String home = '/home-screen';
  static const String propertyDetail = '/property-detail-screen';
  static const String favorites = '/favorites-screen';
  static const String addProperty = '/add-property-screen';
  static const String messages = '/messages-screen';
  static const String profile = '/profile-screen';
  static const String editProfile =
      '/edit-profile-screen'; // example unknown route
  static const String rentPayment = '/rent-payment-screen';
  static const String rentalHistory = '/rental-history-screen';
  static const String myVisits = '/my-visits';
  static const String ownerVisits = '/owner-visits';

  /// Static routes
  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    splash: (context) => const SplashScreen(),
    propertySearch: (context) => const PropertySearchScreen(),
    authentication: (context) => const AuthenticationScreen(),
    onboardingFlow: (context) => const OnboardingFlow(),
    home: (context) => const HomeScreen(),
    propertyDetail: (context) => const PropertyDetailScreen(),
    favorites: (context) => const FavoritesScreen(),
    addProperty: (context) => const AddPropertyScreen(),
    messages: (context) => const MessagesScreen(),
    profile: (context) => const ProfileScreen(),
    editProfile: (context) =>
        const EditProfileScreen(), // example unknown route
    rentPayment: (context) => const RentPaymentScreen(),
    rentalHistory: (context) => const RentalHistoryScreen(),
    myVisits: (context) => const MyVisitsScreen(),
    ownerVisits: (context) => const OwnerVisitsScreen(),
  };

  /// Handles dynamic routes with query params or arguments
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final uri = Uri.tryParse(settings.name ?? '');

    // if (uri != null) {
    //   // ✅ Handle /property-detail-screen?id=prop_001
    //   if (uri.path == propertyDetail) {
    //     final id = uri.queryParameters['id'];
    //     return MaterialPageRoute(
    //       settings: settings,
    //       builder: (_) => PropertyDetailScreen(propertyId: id),
    //     );
    //   }
    // }

    // Fallback → use static routes if matched
    final builder = routes[settings.name];
    if (builder != null) {
      return MaterialPageRoute(
        settings: settings,
        builder: builder,
      );
    }

    return null;
  }

  /// When no route found
  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => const HomeScreen(), // or a 404 screen
    );
  }
}
