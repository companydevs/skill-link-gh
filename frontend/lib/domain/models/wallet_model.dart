import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { topUp, payment, refund, onHold }

enum TransactionStatus { pending, success, failed }

class WalletTransaction {
  final String id;
  final TransactionType type;
  final TransactionStatus status;
  final double amount;
  final String description;
  final String? reference;
  final DateTime createdAt;

  WalletTransaction({
    required this.id,
    required this.type,
    required this.status,
    required this.amount,
    required this.description,
    this.reference,
    required this.createdAt,
  });

  factory WalletTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WalletTransaction(
      id: doc.id,
      type: TransactionType.values.firstWhere(
        (e) => e.name == (data['type'] ?? 'topUp'),
        orElse: () => TransactionType.topUp,
      ),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'pending'),
        orElse: () => TransactionStatus.pending,
      ),
      amount: (data['amount'] ?? 0.0).toDouble(),
      description: data['description'] ?? '',
      reference: data['reference'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'status': status.name,
    'amount': amount,
    'description': description,
    'reference': reference,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
