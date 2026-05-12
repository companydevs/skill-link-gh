import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to check if current user is an artisan
final isArtisanProvider = FutureProvider<bool>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;

  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!doc.exists) return false;

    final userType = doc.data()?['userType'] as String?;
    return userType == 'artisan';
  } catch (e) {
    print('Error checking user type: $e');
    return false;
  }
});
