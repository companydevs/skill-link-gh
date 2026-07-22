import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../data/repository/verification_repository.dart';

class VerificationState {
  final bool isLoading;
  final bool isSubmitted;
  final String? error;
  final String? status; // pending | approved | rejected

  const VerificationState({
    this.isLoading = false,
    this.isSubmitted = false,
    this.error,
    this.status,
  });

  VerificationState copyWith({
    bool? isLoading,
    bool? isSubmitted,
    String? error,
    String? status,
  }) {
    return VerificationState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      error: error,
      status: status ?? this.status,
    );
  }
}

class VerificationNotifier extends StateNotifier<VerificationState> {
  final VerificationRepository _repo;

  VerificationNotifier(this._repo) : super(const VerificationState()) {
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final data = await _repo.getVerificationStatus();
      if (data != null) {
        state = state.copyWith(
          status: data['status'] as String?,
          isSubmitted: true,
        );
      }
    } catch (e) {
      log('⚠️ Could not load verification status: $e');
    }
  }

  Future<bool> submitVerification({
    required String idType,
    required String idNumber,
    required UploadData idFrontImage,
    required UploadData idBackImage,
    UploadData? businessCertImage,
    UploadData? skillCertImage,
    String? businessName,
    String? businessRegNumber,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.submitVerification(
        idType: idType,
        idNumber: idNumber,
        idFrontImage: idFrontImage,
        idBackImage: idBackImage,
        businessCertImage: businessCertImage,
        skillCertImage: skillCertImage,
        businessName: businessName,
        businessRegNumber: businessRegNumber,
      );
      state = state.copyWith(
        isLoading: false,
        isSubmitted: true,
        status: 'pending',
      );
      return true;
    } catch (e) {
      log('❌ Verification submission failed: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final verificationRepositoryProvider = Provider(
  (ref) => VerificationRepository(),
);

final verificationNotifierProvider =
    StateNotifierProvider<VerificationNotifier, VerificationState>((ref) {
      return VerificationNotifier(ref.watch(verificationRepositoryProvider));
    });

// ── Real-time stream of current user's verification fields ────────────────────
// Updates the verified badge INSTANTLY when admin approves from admin panel
final userVerificationStreamProvider = StreamProvider<Map<String, dynamic>>((
  ref,
) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value({});

  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) {
        if (!doc.exists) return <String, dynamic>{};
        final data = doc.data()!;
        return {
          'isVerified': data['isVerified'] ?? false,
          'verificationStatus': data['verificationStatus'] ?? '',
          'verificationBadges': data['verificationBadges'] ?? {},
          'verificationNote': data['verificationNote'] ?? '',
        };
      });
});
