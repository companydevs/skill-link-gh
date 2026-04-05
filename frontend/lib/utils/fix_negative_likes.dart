import 'package:cloud_firestore/cloud_firestore.dart';

/// Utility to fix negative like counts in Firestore
/// Run this once to clean up corrupted data
class FixNegativeLikes {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fix negative likes in reels collection
  static Future<void> fixReelsLikes() async {
    print('🔧 Starting to fix negative likes in reels...');

    try {
      final reelsSnapshot = await _firestore.collection('reels').get();

      int fixedCount = 0;

      for (var doc in reelsSnapshot.docs) {
        final data = doc.data();
        final likes = data['likes'] as int? ?? 0;

        if (likes < 0) {
          // Get actual like count from subcollection
          final likesSnapshot = await doc.reference.collection('likes').get();
          final actualLikes = likesSnapshot.docs.length;

          await doc.reference.update({'likes': actualLikes});

          print('✅ Fixed reel ${doc.id}: $likes -> $actualLikes');
          fixedCount++;
        }
      }

      print('🎉 Fixed $fixedCount reels with negative likes');
    } catch (e) {
      print('❌ Error fixing reels likes: $e');
    }
  }

  /// Fix negative likes in posts collection
  static Future<void> fixPostsLikes() async {
    print('🔧 Starting to fix negative likes in posts...');

    try {
      final postsSnapshot = await _firestore.collection('posts').get();

      int fixedCount = 0;

      for (var doc in postsSnapshot.docs) {
        final data = doc.data();
        final likes = data['likes'] as int? ?? 0;

        if (likes < 0) {
          // Get actual like count from subcollection
          final likesSnapshot = await doc.reference.collection('likes').get();
          final actualLikes = likesSnapshot.docs.length;

          await doc.reference.update({'likes': actualLikes});

          print('✅ Fixed post ${doc.id}: $likes -> $actualLikes');
          fixedCount++;
        }
      }

      print('🎉 Fixed $fixedCount posts with negative likes');
    } catch (e) {
      print('❌ Error fixing posts likes: $e');
    }
  }

  /// Fix all negative likes (both reels and posts)
  static Future<void> fixAll() async {
    await fixReelsLikes();
    await fixPostsLikes();
  }
}
