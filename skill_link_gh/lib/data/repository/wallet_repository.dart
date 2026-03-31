import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_link_gh/domain/models/wallet_model.dart';

class WalletRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  DocumentReference get _walletRef =>
      _firestore.collection('wallets').doc(_uid);

  CollectionReference get _txRef => _walletRef.collection('transactions');

  /// Get current wallet balance
  Future<double> getBalance() async {
    try {
      final doc = await _walletRef.get();
      if (!doc.exists) return 0.0;
      return ((doc.data() as Map<String, dynamic>)['balance'] ?? 0.0)
          .toDouble();
    } catch (e) {
      log('Error fetching wallet balance: $e');
      return 0.0;
    }
  }

  /// Stream wallet balance in real-time
  Stream<double> balanceStream() {
    return _walletRef.snapshots().map((doc) {
      if (!doc.exists) return 0.0;
      return ((doc.data() as Map<String, dynamic>)['balance'] ?? 0.0)
          .toDouble();
    });
  }

  /// Get transaction history
  Future<List<WalletTransaction>> getTransactions({int limit = 20}) async {
    try {
      final snapshot = await _txRef
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs.map(WalletTransaction.fromFirestore).toList();
    } catch (e) {
      log('Error fetching transactions: $e');
      return [];
    }
  }

  /// Initiate a top-up via Paystack — returns {paymentUrl, reference}
  Future<Map<String, dynamic>> initiateTopUp(double amount) async {
    try {
      final callable = _functions.httpsCallable('initiateWalletTopUp');
      final result = await callable.call({'amount': amount});
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      log('Error initiating top-up: $e');
      rethrow;
    }
  }

  /// Verify top-up after Paystack redirect
  Future<bool> verifyTopUp(String reference) async {
    try {
      final callable = _functions.httpsCallable('verifyWalletTopUp');
      final result = await callable.call({'reference': reference});
      final data = Map<String, dynamic>.from(result.data);
      return data['success'] == true;
    } catch (e) {
      log('Error verifying top-up: $e');
      return false;
    }
  }

  /// Pay for a service using wallet balance
  Future<bool> payWithWallet({
    required String bookingId,
    required double amount,
  }) async {
    try {
      final callable = _functions.httpsCallable('payWithWallet');
      final result = await callable.call({
        'bookingId': bookingId,
        'amount': amount,
      });
      final data = Map<String, dynamic>.from(result.data);
      return data['success'] == true;
    } catch (e) {
      log('Error paying with wallet: $e');
      rethrow;
    }
  }
}
