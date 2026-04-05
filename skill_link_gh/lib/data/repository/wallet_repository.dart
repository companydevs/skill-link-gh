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

  /// Stream on-hold balance (earnings pending QR release)
  Stream<double> onHoldStream() {
    return _walletRef.snapshots().map((doc) {
      if (!doc.exists) return 0.0;
      return ((doc.data() as Map<String, dynamic>)['onHoldBalance'] ?? 0.0)
          .toDouble();
    });
  }

  /// Place artisan payment on hold when booking is confirmed
  Future<bool> holdPaymentForArtisan({
    required String bookingId,
    required String artisanId,
    required double amount,
  }) async {
    try {
      final artisanWallet = _firestore.collection('wallets').doc(artisanId);
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(artisanWallet);
        final current = snap.exists
            ? ((snap.data()!['onHoldBalance'] ?? 0.0) as num).toDouble()
            : 0.0;
        tx.set(artisanWallet, {
          'onHoldBalance': current + amount,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        tx.set(artisanWallet.collection('transactions').doc(), {
          'type': 'onHold',
          'status': 'pending',
          'amount': amount,
          'description': 'Payment on hold for booking $bookingId',
          'reference': bookingId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
      log('✅ Payment held for artisan $artisanId');
      return true;
    } catch (e) {
      log('Error holding payment: $e');
      return false;
    }
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

  /// Release payment to artisan after QR scan verification
  /// Moves amount from onHoldBalance → spendable balance
  Future<bool> releasePaymentToArtisan({
    required String bookingId,
    required String artisanId,
    required double amount,
  }) async {
    try {
      final artisanWallet = _firestore.collection('wallets').doc(artisanId);
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(artisanWallet);
        final currentBalance = snap.exists
            ? ((snap.data()!['balance'] ?? 0.0) as num).toDouble()
            : 0.0;
        final currentHold = snap.exists
            ? ((snap.data()!['onHoldBalance'] ?? 0.0) as num).toDouble()
            : 0.0;
        // Move from onHold → spendable balance
        tx.set(artisanWallet, {
          'balance': currentBalance + amount,
          'onHoldBalance': (currentHold - amount).clamp(0.0, double.infinity),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        tx.set(artisanWallet.collection('transactions').doc(), {
          'type': 'payment',
          'status': 'success',
          'amount': amount,
          'description': 'Payment released for booking $bookingId',
          'reference': bookingId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
      // Mark booking completed
      await _firestore.collection('bookings').doc(bookingId).update({
        'paymentReleased': true,
        'paymentReleasedAt': FieldValue.serverTimestamp(),
        'status': 'completed',
      });
      log('✅ Payment released to artisan $artisanId');
      return true;
    } catch (e) {
      log('Error releasing payment: $e');
      return false;
    }
  }

  /// Refund client wallet when booking expires without artisan acceptance
  Future<bool> refundExpiredBooking({
    required String bookingId,
    required String clientId,
    required double amount,
  }) async {
    try {
      final bookingRef = _firestore.collection('bookings').doc(bookingId);
      final clientWallet = _firestore.collection('wallets').doc(clientId);

      await _firestore.runTransaction((tx) async {
        final bookingSnap = await tx.get(bookingRef);
        if (!bookingSnap.exists) return;
        final data = bookingSnap.data()!;
        // Only refund if still pending and not already refunded
        if (data['status'] != 'pending') return;
        if (data['refunded'] == true) return;

        final walletSnap = await tx.get(clientWallet);
        final current = walletSnap.exists
            ? ((walletSnap.data()!['balance'] ?? 0.0) as num).toDouble()
            : 0.0;

        tx.update(bookingRef, {
          'status': 'cancelled',
          'refunded': true,
          'refundedAt': FieldValue.serverTimestamp(),
          'cancellationReason': 'Artisan did not accept before booking date',
        });

        tx.set(clientWallet, {
          'balance': current + amount,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        tx.set(clientWallet.collection('transactions').doc(), {
          'type': 'refund',
          'status': 'success',
          'amount': amount,
          'description': 'Refund: Artisan did not accept booking $bookingId',
          'reference': bookingId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      log('✅ Refund processed for expired booking $bookingId');
      return true;
    } catch (e) {
      log('Error processing refund: $e');
      return false;
    }
  }
}
