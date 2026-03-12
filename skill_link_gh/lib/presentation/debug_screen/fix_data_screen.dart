import 'package:flutter/material.dart';
import 'package:skill_link_gh/utils/fix_negative_likes.dart';

/// Debug screen to fix corrupted data
/// Navigate to this screen and tap the button to fix negative likes
class FixDataScreen extends StatefulWidget {
  const FixDataScreen({super.key});

  @override
  State<FixDataScreen> createState() => _FixDataScreenState();
}

class _FixDataScreenState extends State<FixDataScreen> {
  bool _isFixing = false;
  String _status = 'Ready to fix negative likes';

  Future<void> _fixNegativeLikes() async {
    setState(() {
      _isFixing = true;
      _status = 'Fixing negative likes...';
    });

    try {
      await FixNegativeLikes.fixAll();

      if (mounted) {
        setState(() {
          _isFixing = false;
          _status = '✅ All negative likes fixed!';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully fixed all negative likes!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFixing = false;
          _status = '❌ Error: $e';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fix Data'),
        backgroundColor: theme.colorScheme.surface,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.build_circle,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Fix Negative Likes',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _status,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_isFixing)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  onPressed: _fixNegativeLikes,
                  icon: const Icon(Icons.healing),
                  label: const Text('Fix All Negative Likes'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'This will scan all reels and posts and fix any negative like counts',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
