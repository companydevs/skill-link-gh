import 'package:flutter/material.dart';
import 'package:skill_link_gh/domain/models/post_model.dart';
import 'package:skill_link_gh/presentation/in_app_messaging/in_app_messaging.dart';
import 'package:skill_link_gh/presentation/login_screen/login_screen.dart';
import 'package:skill_link_gh/presentation/onboarding_flow/onboarding_flow.dart';
import 'package:skill_link_gh/presentation/otp_verification_screen/otp_verification_screen.dart';
import 'package:skill_link_gh/presentation/posts_comments_detail_screen/post_comments_detail_screen.dart';
import 'package:skill_link_gh/presentation/splash_screen/splash_screen.dart';
import 'package:skill_link_gh/presentation/user_type_selection_screen/user_type_selection_screen.dart';
import 'package:skill_link_gh/presentation/edit_profile_screen/edit_profile_screen.dart';
import 'package:skill_link_gh/presentation/verification_screen/verification_screen.dart';
import 'package:skill_link_gh/presentation/payment_verification_screen/payment_verification_screen.dart';
import 'package:skill_link_gh/presentation/booking_tracking_screen/booking_tracking_screen.dart';
import 'package:skill_link_gh/presentation/debug_screen/fix_data_screen.dart';
import 'package:skill_link_gh/presentation/debug_screen/cleanup_videos_screen.dart';
import 'package:skill_link_gh/test_reels_screen.dart';
import '../presentation/artisan_profile_screen/artisan_profile_screen.dart';
import '../presentation/reels_screen/reels_screen.dart';
import '../presentation/service_booking_screen/service_booking_screen.dart';
import '../presentation/registration_screen/registration_screen.dart';
import '../presentation/search_and_discovery_screen/search_and_discovery_screen.dart';
import '../presentation/posts_homepage/posts_homepage.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String splashScreen = '/splash-screen';
  static const String onboardingScreen = '/onboarding-screen';
  static const String loginScreen = '/login-screen';
  static const String userTypeSelectionScreen = '/user-type-selection-screen';
  static const String otpVerificationScreen = '/otp-verification-screen';
  static const String artisanProfile = '/artisan-profile-screen';
  static const String reels = '/reels-screen';
  static const String serviceBooking = '/service-booking-screen';
  static const String registration = '/registration-screen';
  static const String searchAndDiscovery = '/search-and-discovery-screen';
  static const String postsHomepage = '/posts-homepage';
  static const String postCommentScreen = '/post-comment-screen';
  static const String inAppMessagingScreen = '/in-app-messaging-screen';
  static const String testReels = '/test-reels';
  static const String editProfileScreen = '/edit-profile-screen';
  static const String verificationScreen = '/verification-screen';
  static const String paymentVerificationScreen =
      '/payment-verification-screen';
  static const String bookingTrackingScreen = '/booking-tracking-screen';
  static const String fixDataScreen = '/fix-data-screen';
  static const String cleanupVideosScreen = '/cleanup-videos-screen';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    splashScreen: (context) => const SplashScreen(),
    onboardingScreen: (context) => const OnboardingFlow(),
    loginScreen: (context) => const LoginScreen(),
    userTypeSelectionScreen: (context) => const UserTypeSelectionScreen(),
    otpVerificationScreen: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final email = args?['email'] as String?;
      if (email == null) {
        throw Exception("Email is required for OTP verification");
      }
      return OtpVerificationScreen(email: email);
    },

    artisanProfile: (context) => const ArtisanProfileScreen(),
    reels: (context) => ReelsScreen(),
    serviceBooking: (context) => const ServiceBookingScreen(),
    registration: (context) => const RegistrationScreen(),
    searchAndDiscovery: (context) => const SearchAndDiscoveryScreen(),
    postsHomepage: (context) => const PostsHomepage(),
    postCommentScreen: (context) {
      final post = ModalRoute.of(context)?.settings.arguments as PostModel?;
      if (post == null) {
        throw Exception('PostModel is required to view comments');
      }
      return PostCommentsDetailsScreen(post: post);
    },

    inAppMessagingScreen: (context) => const InAppMessaging(),
    testReels: (context) => const TestReelsScreen(),
    editProfileScreen: (context) => const EditProfileScreen(),
    verificationScreen: (context) => const VerificationScreen(),
    paymentVerificationScreen: (context) => const PaymentVerificationScreen(),
    bookingTrackingScreen: (context) => const BookingTrackingScreen(),
    fixDataScreen: (context) => const FixDataScreen(),
    cleanupVideosScreen: (context) => const CleanupVideosScreen(),
  };
}
