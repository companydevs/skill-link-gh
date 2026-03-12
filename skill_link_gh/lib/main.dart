import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';

import '../core/app_export.dart';
import '../widgets/custom_error_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Wait for Firebase to finish initializing

  // Configure Firebase App Check for debug/development
  await FirebaseAppCheck.instance.activate(
    // For debug builds, use debug provider
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  bool hasShownError = false;

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!hasShownError) {
      hasShownError = true;

      // Reset flag after 3 seconds to allow error widget on new screens
      Future.delayed(const Duration(seconds: 5), () {
        hasShownError = false;
      });

      return CustomErrorWidget(errorDetails: details);
    }
    return const SizedBox.shrink();
  };

  // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
  Future.wait([
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
  ]).then((value) {
    runApp(ProviderScope(child: const MyApp()));
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, screenType) {
        return MaterialApp(
          title: 'skilllink_gh',
          themeMode: ThemeMode.system, // ← Change this from .light to .system
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          // themeMode: ThemeMode.light,
          // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(1.0)),
              child: child!,
            );
          },
          // 🚨 END CRITICAL SECTION
          debugShowCheckedModeBanner: false,
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.initial,
        );
      },
    );
  }
}
