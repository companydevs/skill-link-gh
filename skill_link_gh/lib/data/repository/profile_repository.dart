import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user's profile data
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;

      final data = doc.data()!;

      // Add computed fields
      data['id'] = user.uid;
      data['memberSince'] =
          (data['createdAt'] as Timestamp?)?.toDate().toIso8601String() ??
          DateTime.now().toIso8601String();

      // Use Firebase Auth photoURL as fallback if no profileImage stored in Firestore
      if ((data['profileImage'] as String?)?.isEmpty ?? true) {
        final firestorePhoto = data['photoUrl'] as String? ?? '';
        final authPhoto = user.photoURL ?? '';
        final fallback = firestorePhoto.isNotEmpty ? firestorePhoto : authPhoto;
        if (fallback.isNotEmpty) {
          data['profileImage'] = fallback;
          // Write it back so other users can see it too
          await _firestore.collection('users').doc(user.uid).update({
            'profileImage': fallback,
            'photoUrl': fallback,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      return data;
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }

  /// Get artisan's portfolio images
  Future<List<Map<String, dynamic>>> getPortfolioImages(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('portfolio')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching portfolio: $e');
      return [];
    }
  }

  /// Get artisan's reviews
  Future<List<Map<String, dynamic>>> getReviews(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching reviews: $e');
      return [];
    }
  }

  /// Get artisan's services
  Future<List<Map<String, dynamic>>> getServices(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('services')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching services: $e');
      return [];
    }
  }

  /// Get jobs done, bids accepted, and post count for a user
  Future<Map<String, int>> getSocialCounts(String userId) async {
    try {
      final results = await Future.wait([
        // Completed bookings where this user was the artisan
        _firestore
            .collection('bookings')
            .where('artisanId', isEqualTo: userId)
            .where('status', isEqualTo: 'completed')
            .count()
            .get(),
        // Confirmed/accepted bookings where this user was the artisan
        _firestore
            .collection('bookings')
            .where('artisanId', isEqualTo: userId)
            .where('status', isEqualTo: 'confirmed')
            .count()
            .get(),
        // Posts by this user
        _firestore
            .collection('posts')
            .where('userId', isEqualTo: userId)
            .count()
            .get(),
      ]);
      return {
        'jobsDone': results[0].count ?? 0,
        'bidsAccepted': results[1].count ?? 0,
        'posts': results[2].count ?? 0,
      };
    } catch (e) {
      print('Error fetching profile counts: $e');
      return {'jobsDone': 0, 'bidsAccepted': 0, 'posts': 0};
    }
  }

  /// Update profile data
  Future<void> updateProfile(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    try {
      await _firestore.collection('users').doc(user.uid).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Keep Firebase Auth displayName in sync so it never goes stale
      if (data.containsKey('fullName')) {
        await user.updateDisplayName(data['fullName'] as String?);
      }
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }
}
