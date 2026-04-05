import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class Cleanup4KVideos {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// List all videos with their sizes
  static Future<Map<String, dynamic>> listVideoSizes() async {
    try {
      debugPrint('📋 Fetching video sizes...');

      final callable = _functions.httpsCallable('listVideoSizes');
      final result = await callable.call();

      debugPrint('✅ Got video list: ${result.data}');
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('❌ Error listing videos: $e');
      rethrow;
    }
  }

  /// Delete all 4K videos (>10MB)
  static Future<Map<String, dynamic>> cleanup4KVideos() async {
    try {
      debugPrint('🗑️ Starting 4K video cleanup...');

      final callable = _functions.httpsCallable('cleanup4KVideos');
      final result = await callable.call();

      debugPrint('✅ Cleanup complete: ${result.data}');
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('❌ Error during cleanup: $e');
      rethrow;
    }
  }
}
