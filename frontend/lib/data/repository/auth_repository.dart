import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:skill_link_gh/domain/models/userTypes.dart';
import '../../domain/models/user_model.dart';

//re_ELnkx9vT_ND9bpNDnajjngqHu68dT4mpy
class AuthRepository {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final functions = FirebaseFunctions.instance;

  Future<Map<String, dynamic>> registerUser(
    UserModel user, {
    String provider = "password",
  }) async {
    try {
      final result = await functions.httpsCallable('registerUser').call({
        ...user.toJson(),
        'provider': provider,
        'isArtisan': user.userType == UserType.artisan,
      });
      if (result.data['success'] != true) {
        throw Exception(result.data['message'] ?? 'Registration failed');
      }
      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      throw Exception(_mapFunctionError(e));
    } catch (_) {
      throw Exception('Registration failed. Please try again.');
    }
  }

  String _mapFunctionError(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'already-exists':
        return 'This email is already registered. Please log in or use another email.';

      case 'invalid-argument':
        return 'Some information you entered is invalid. Please check and try again.';

      case 'unauthenticated':
        return 'You are not authorized. Please log in again.';

      case 'permission-denied':
        return 'You do not have permission to perform this action.';

      case 'unavailable':
        return 'Service temporarily unavailable. Please check your internet connection.';

      default:
        return e.message ?? 'Registration failed. Please try again.';
    }
  }

  // Initialize GoogleSignIn properly

  Future<UserCredential> signUpWithGoogle({required String userType}) async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      final googleUser = await _googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) throw Exception("Google user is null");

      // Check if an account already exists with this email (e.g. registered via email/password)
      final emailQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();

      if (emailQuery.docs.isNotEmpty) {
        final existingDoc = emailQuery.docs.first;
        final existingProvider =
            existingDoc.data()['provider'] as String? ?? 'password';
        // Sign out the Google session we just created — don't keep it
        await _auth.signOut();
        await _googleSignIn.signOut();
        throw Exception(
          'An account with this email already exists. '
          'Please sign in with ${existingProvider == 'google' ? 'Google' : 'your email and password'}.',
        );
      }

      final doc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final snapshot = await doc.get();

      if (!snapshot.exists) {
        await doc.set({
          'uid': user.uid,
          'fullName': user.displayName ?? '',
          'email': user.email ?? '',
          'userType': userType,
          'role': userType,
          'profileImage': user.photoURL ?? '',
          'photoUrl': user.photoURL ?? '',
          'provider': 'google',
          'isEmailVerified': true, // Google confirmed the email
          'isVerified': false, // Admin identity verification — NOT auto-granted
          'verificationStatus': '', // Not submitted yet
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return userCredential;
    } catch (e) {
      // Re-throw clean messages directly without wrapping
      if (e is Exception) {
        final msg = e.toString();
        if (msg.contains('already exists') ||
            msg.contains('already registered')) {
          rethrow;
        }
      }
      throw Exception("Google Sign-Up failed: $e");
    }
  }

  Future<UserCredential> signInWithGoogle({required String userType}) async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      final googleUser = await _googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) throw Exception('Google sign-in returned no user');

      // Check Firestore for existing profile
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final doc = await docRef.get();

      if (!doc.exists) {
        // No doc by UID — check if email exists under a different UID
        // (manually created account scenario)
        final emailQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get();

        if (emailQuery.docs.isNotEmpty) {
          // Account exists with same email — migrate it to this Google UID
          final existingData = emailQuery.docs.first.data();
          final oldUid = emailQuery.docs.first.id;

          // Copy data to new UID doc, update provider to google
          await docRef.set({
            ...existingData,
            'uid': user.uid,
            'provider': 'google',
            'userType':
                existingData['userType'] ?? 'artisan', // preserve userType
            'profileImage':
                (existingData['profileImage'] as String?)?.isNotEmpty == true
                ? existingData['profileImage']
                : (user.photoURL ?? ''),
            'photoUrl':
                (existingData['photoUrl'] as String?)?.isNotEmpty == true
                ? existingData['photoUrl']
                : (user.photoURL ?? ''),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          // Delete old doc if different UID
          if (oldUid != user.uid) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(oldUid)
                .delete();
          }
        } else {
          // Completely new — no account at all
          await _auth.signOut();
          await _googleSignIn.signOut();
          throw Exception(
            'No account found for this Google account. Please sign up first.',
          );
        }
      } else {
        // Doc exists — update provider to google and sync photo if needed
        final data = doc.data()!;
        final existingPhoto = data['profileImage'] as String? ?? '';
        final googlePhoto = user.photoURL ?? '';

        await docRef.update({
          'provider': 'google',
          if (googlePhoto.isNotEmpty && existingPhoto.isEmpty)
            'profileImage': googlePhoto,
          if (googlePhoto.isNotEmpty && existingPhoto.isEmpty)
            'photoUrl': googlePhoto,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return userCredential;
    } catch (e) {
      if (e is Exception && e.toString().contains('No account found')) {
        rethrow;
      }
      throw Exception('Google Sign-In failed: $e');
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;
}
