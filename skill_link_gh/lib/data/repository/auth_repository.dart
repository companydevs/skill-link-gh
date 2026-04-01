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
      final googleUser = await _googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) throw Exception("Google user is null");

      final doc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final snapshot = await doc.get();

      if (!snapshot.exists) {
        await doc.set({
          'uid': user.uid,
          'fullName': user.displayName ?? '',
          'email': user.email ?? '',
          'role': userType,
          'photoUrl': user.photoURL ?? '',
          'isVerified': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        await registerUser(
          UserModel(
            fullName: user.displayName ?? '',
            email: user.email ?? '',
            userType: (userType == 'artisan')
                ? UserType.artisan
                : UserType.client,
            password: '',
            phone: '',
          ),
          provider: 'google',
        );
      }

      return userCredential;
    } catch (e) {
      throw Exception("Google Sign-Up failed: $e");
    }
  }

  Future<UserCredential> signInWithGoogle({required String userType}) async {
    try {
      final googleUser = await _googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      throw Exception('Google Sign-In failed: $e');
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;
}
