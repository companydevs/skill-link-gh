import 'package:flutter/material.dart';
import 'package:skill_link_gh/routes/app_routes.dart';

/// Quick test widget to verify Messages navigation works
///
/// Usage: Replace the home screen temporarily with this widget
/// in main.dart to test direct navigation to Messages screen
class TestMessagesNavigation extends StatelessWidget {
  const TestMessagesNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Messages Navigation')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Test Navigation to Messages Screen',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                debugPrint(
                  '🧪 Testing navigation to: ${AppRoutes.conversationsScreen}',
                );
                Navigator.pushNamed(context, AppRoutes.conversationsScreen);
              },
              child: const Text('Go to Messages Screen'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                debugPrint('🧪 Testing navigation to: /conversations-screen');
                Navigator.pushNamed(context, '/conversations-screen');
              },
              child: const Text('Go to Messages (Direct Route)'),
            ),
            const SizedBox(height: 40),
            const Text(
              'Check the console for debug logs',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
