import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/models/user_model.dart';

class AuthRepository {
    final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

 final FirebaseAuth _auth = FirebaseAuth.instance;
  final functions = FirebaseFunctions.instance;

  Future<void> registerUser(UserModel user) async {
    try {
      final result = await functions
          .httpsCallable('registerUser')
          .call(user.toJson());
      if (result.data['success'] != true) {
        throw Exception(result.data['message'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }


  // Initialize GoogleSignIn properly

  /// Google Sign-In
  Future<UserCredential> signInWithGoogle({required String userType}) async {
    try {
      //  Pick Google account
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
      if (googleUser == null) {
        throw Exception("Google sign-in cancelled");
      }

      //  Get OAuth tokens
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      //  In version 7+, accessToken and idToken are nullable
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.idToken,
        idToken: googleAuth.idToken,
      );

      //  Firebase sign-in
      final userCredential = await _auth.signInWithCredential(credential);

      //  Save profile if first login
      await _saveUserProfileIfNew(userCredential, userType);

      return userCredential;
    } catch (e) {
      throw Exception("Google Sign-In failed: $e");
    }
  }

  Future<void> _saveUserProfileIfNew(
      UserCredential userCredential, String userType) async {
    final user = userCredential.user;
    if (user == null) return;

    final doc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snapshot = await doc.get();

    if (!snapshot.exists) {
      await doc.set({
        'uid': user.uid,
        'fullName': user.displayName ?? '',
        'email': user.email ?? '',
        'role': userType,
        'photoUrl': user.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;
}
