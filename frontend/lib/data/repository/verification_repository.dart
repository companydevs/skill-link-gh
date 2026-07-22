import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

// Model to handle both mobile and web uploads
class UploadData {
  final File? file;
  final Uint8List? bytes;
  final String? filename;

  UploadData({this.file, this.bytes, this.filename});

  bool get isValid => file != null || bytes != null;
}

class VerificationRepository {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;

  String get _uid => _auth.currentUser!.uid;

  /// Upload a file to Firebase Storage and return the download URL
  /// Supports both mobile (File) and web (Uint8List) platforms
  Future<String> _uploadFile(UploadData data, String path) async {
    try {
      final ref = _storage.ref().child(path);

      if (kIsWeb && data.bytes != null) {
        // Web upload using bytes
        final task = await ref.putData(
          data.bytes!,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        return await task.ref.getDownloadURL();
      } else if (data.file != null) {
        // Mobile upload using File
        final task = await ref.putFile(data.file!);
        return await task.ref.getDownloadURL();
      } else {
        throw Exception('Invalid upload data: neither file nor bytes provided');
      }
    } catch (e) {
      log('❌ Error uploading file to $path: $e');
      throw Exception('Failed to upload file: ${e.toString()}');
    }
  }

  /// Submit verification request
  Future<void> submitVerification({
    required String idType,
    required String idNumber,
    required UploadData idFrontImage,
    required UploadData idBackImage,
    UploadData? businessCertImage,
    UploadData? skillCertImage,
    String? businessName,
    String? businessRegNumber,
  }) async {
    try {
      log('🔄 Submitting verification for user: $_uid');

      // Upload ID images
      log('📤 Uploading ID front image...');
      final idFrontUrl = await _uploadFile(
        idFrontImage,
        'verifications/$_uid/id_front.jpg',
      );

      log('📤 Uploading ID back image...');
      final idBackUrl = await _uploadFile(
        idBackImage,
        'verifications/$_uid/id_back.jpg',
      );

      // Upload optional docs
      String? businessCertUrl;
      if (businessCertImage != null && businessCertImage.isValid) {
        log('📤 Uploading business certificate...');
        businessCertUrl = await _uploadFile(
          businessCertImage,
          'verifications/$_uid/business_cert.jpg',
        );
      }

      String? skillCertUrl;
      if (skillCertImage != null && skillCertImage.isValid) {
        log('📤 Uploading skill certificate...');
        skillCertUrl = await _uploadFile(
          skillCertImage,
          'verifications/$_uid/skill_cert.jpg',
        );
      }

      // Get user info
      log('📋 Fetching user information...');
      final userDoc = await _firestore.collection('users').doc(_uid).get();
      final userData = userDoc.data() ?? {};
      final userName = userData['fullName'] ?? userData['displayName'] ?? '';
      final userEmail = userData['email'] ?? _auth.currentUser?.email ?? '';

      // Save to Firestore
      log('💾 Saving verification data to Firestore...');
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
      log('📝 Updating user verification status...');
      await _firestore.collection('users').doc(_uid).update({
        'verificationStatus': 'pending',
      });

      log('✅ Verification submitted successfully');
    } catch (e) {
      log('❌ Error submitting verification: $e');
      // Re-throw with user-friendly message
      throw Exception('Failed to submit verification. Please try again.');
    }
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
