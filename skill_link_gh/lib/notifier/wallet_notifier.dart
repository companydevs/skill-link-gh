import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_link_gh/data/repository/wallet_repository.dart';
import 'package:skill_link_gh/domain/models/wallet_model.dart';

class WalletState {
  final double balance;
  final List<WalletTransaction> transactions;
  final bool isLoading;
  final bool isProcessing;
  final String? error;

  const WalletState({
    this.balance = 0.0,
    this.transactions = const [],
    this.isLoading = false,
    this.isProcessing = false,
    this.error,
  });

  WalletState copyWith({
    double? balance,
    List<WalletTransaction>? transactions,
    bool? isLoading,
    bool? isProcessing,
    String? error,
  }) => WalletState(
    balance: balance ?? this.balance,
    transactions: transactions ?? this.transactions,
    isLoading: isLoading ?? this.isLoading,
    isProcessing: isProcessing ?? this.isProcessing,
    error: error,
  );
}

final walletRepositoryProvider = Provider<WalletRepository>(
  (_) => WalletRepository(),
);

class WalletNotifier extends Notifier<WalletState> {
  WalletRepository get _repo => ref.read(walletRepositoryProvider);
  StreamSubscription<double>? _balanceSub;

  @override
  WalletState build() {
    Future.microtask(() => _init());
    ref.onDispose(() => _balanceSub?.cancel());
    return const WalletState(isLoading: true);
  }

  void _init() {
    _balanceSub = _repo.balanceStream().listen(
      (balance) => state = state.copyWith(balance: balance),
    );
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final txs = await _repo.getTransactions();
      state = state.copyWith(transactions: txs, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Returns {paymentUrl, reference} for the top-up flow
  Future<Map<String, dynamic>> initiateTopUp(double amount) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final result = await _repo.initiateTopUp(amount);
      state = state.copyWith(isProcessing: false);
      return result;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      rethrow;
    }
  }

  Future<bool> verifyTopUp(String reference) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final success = await _repo.verifyTopUp(reference);
      if (success) await loadTransactions();
      state = state.copyWith(isProcessing: false);
      return success;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  Future<bool> payWithWallet({
    required String bookingId,
    required double amount,
  }) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final success = await _repo.payWithWallet(
        bookingId: bookingId,
        amount: amount,
      );
      if (success) await loadTransactions();
      state = state.copyWith(isProcessing: false);
      return success;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      rethrow;
    }
  }

  Future<bool> releasePaymentToArtisan({
    required String bookingId,
    required String artisanId,
    required double amount,
  }) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final success = await _repo.releasePaymentToArtisan(
        bookingId: bookingId,
        artisanId: artisanId,
        amount: amount,
      );
      if (success) await loadTransactions();
      state = state.copyWith(isProcessing: false);
      return success;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  Future<bool> refundExpiredBooking({
    required String bookingId,
    required String clientId,
    required double amount,
  }) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final success = await _repo.refundExpiredBooking(
        bookingId: bookingId,
        clientId: clientId,
        amount: amount,
      );
      if (success) await loadTransactions();
      state = state.copyWith(isProcessing: false);
      return success;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }
}
