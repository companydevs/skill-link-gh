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

    final data = doc.data()!;
    // Check both 'userType' and 'role' fields for compatibility
    final userType = data['userType'] as String?;
    final role = data['role'] as String?;
    return userType == 'artisan' || role == 'artisan';
  } catch (e) {
    return false;
  }
});

/// Provider to get the user type string
final userTypeProvider = FutureProvider<String>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return 'client';

  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!doc.exists) return 'client';

    final data = doc.data()!;
    // Check both 'userType' and 'role' fields for compatibility
    final userType = data['userType'] as String?;
    final role = data['role'] as String?;
    return userType ?? role ?? 'client';
  } catch (e) {
    return 'client';
  }
});
