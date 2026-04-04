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
          'role': userType,
          'profileImage': user.photoURL ?? '',
          'photoUrl': user.photoURL ?? '',
          'provider': 'google',
          'isVerified': true,
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

      // Verify this Google account has a registered profile in Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        // Check if an account exists with this email but a different provider
        final emailQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get();

        await _auth.signOut();
        await _googleSignIn.signOut();

        if (emailQuery.docs.isNotEmpty) {
          final existingProvider =
              emailQuery.docs.first.data()['provider'] as String? ?? 'password';
          if (existingProvider != 'google') {
            throw Exception(
              'This email is registered with email & password. '
              'Please sign in with your email and password instead.',
            );
          }
        }

        throw Exception(
          'No account found for this Google account. Please sign up first.',
        );
      }

      // Account exists — check it was registered with Google
      final registeredProvider =
          doc.data()?['provider'] as String? ?? 'password';
      if (registeredProvider != 'google') {
        await _auth.signOut();
        await _googleSignIn.signOut();
        throw Exception(
          'This account was registered with email & password. '
          'Please sign in with your email and password instead.',
        );
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
