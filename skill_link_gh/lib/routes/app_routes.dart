import 'package:flutter/material.dart';
import '../presentation/artisan_profile_screen/artisan_profile_screen.dart';
import '../presentation/reels_screen/reels_screen.dart';
import '../presentation/service_booking_screen/service_booking_screen.dart';
import '../presentation/registration_screen/registration_screen.dart';
import '../presentation/search_and_discovery_screen/search_and_discovery_screen.dart';
import '../presentation/posts_homepage/posts_homepage.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String artisanProfile = '/artisan-profile-screen';
  static const String reels = '/reels-screen';
  static const String serviceBooking = '/service-booking-screen';
  static const String registration = '/registration-screen';
  static const String searchAndDiscovery = '/search-and-discovery-screen';
  static const String postsHomepage = '/posts-homepage';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const PostsHomepage(),
    artisanProfile: (context) => const ArtisanProfileScreen(),
    reels: (context) => const ReelsScreen(),
    serviceBooking: (context) => const ServiceBookingScreen(),
    registration: (context) => const RegistrationScreen(),
    searchAndDiscovery: (context) => const SearchAndDiscoveryScreen(),
    postsHomepage: (context) => const PostsHomepage(),
    // TODO: Add your other routes here
  };
}
