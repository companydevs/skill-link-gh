import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class VerificationRepository {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;

  String get _uid => _auth.currentUser!.uid;

  /// Upload a file to Firebase Storage and return the download URL
  Future<String> _uploadFile(File file, String path) async {
    final ref = _storage.ref().child(path);
    final task = await ref.putFile(file);
    return await task.ref.getDownloadURL();
  }

  /// Submit verification request
  Future<void> submitVerification({
    required String idType,
    required String idNumber,
    required File idFrontImage,
    required File idBackImage,
    File? businessCertImage,
    File? skillCertImage,
    String? businessName,
    String? businessRegNumber,
  }) async {
    log('🔄 Submitting verification for user: $_uid');

    // Upload ID images
    final idFrontUrl = await _uploadFile(
      idFrontImage,
      'verifications/$_uid/id_front.jpg',
    );
    final idBackUrl = await _uploadFile(
      idBackImage,
      'verifications/$_uid/id_back.jpg',
    );

    // Upload optional docs
    String? businessCertUrl;
    if (businessCertImage != null) {
      businessCertUrl = await _uploadFile(
        businessCertImage,
        'verifications/$_uid/business_cert.jpg',
      );
    }

    String? skillCertUrl;
    if (skillCertImage != null) {
      skillCertUrl = await _uploadFile(
        skillCertImage,
        'verifications/$_uid/skill_cert.jpg',
      );
    }

    // Get user info
    final userDoc = await _firestore.collection('users').doc(_uid).get();
    final userData = userDoc.data() ?? {};
    final userName = userData['fullName'] ?? userData['displayName'] ?? '';
    final userEmail = userData['email'] ?? _auth.currentUser?.email ?? '';

    // Save to Firestore
    await _firestore.collection('verifications').doc(_uid).set({
      'userId': _uid,
      'userName': userName,
      'userEmail': userEmail,
      'idType': idType,
      'idNumber': idNumber,
      'idFrontUrl': idFrontUrl,
      'idBackUrl': idBackUrl,
      'businessName': businessName ?? '',
      'businessRegNumber': businessRegNumber ?? '',
      'businessCertUrl': businessCertUrl ?? '',
      'skillCertUrl': skillCertUrl ?? '',
      'status': 'pending', // pending | approved | rejected
      'adminNote': '',
      'submittedAt': FieldValue.serverTimestamp(),
      'reviewedAt': null,
    });

    // Update user's verification status
    await _firestore.collection('users').doc(_uid).update({
      'verificationStatus': 'pending',
    });

    log('✅ Verification submitted successfully');
  }

  /// Get current user's verification status
  Future<Map<String, dynamic>?> getVerificationStatus() async {
    final doc = await _firestore.collection('verifications').doc(_uid).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  /// Stream of verification status
  Stream<DocumentSnapshot> verificationStatusStream() {
    return _firestore.collection('verifications').doc(_uid).snapshots();
  }
}
