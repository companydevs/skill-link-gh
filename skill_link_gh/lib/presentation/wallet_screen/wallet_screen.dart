import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:skill_link_gh/domain/models/wallet_model.dart';
import 'package:skill_link_gh/provider/wallet_provider.dart';
import 'package:skill_link_gh/widgets/custom_app_bar.dart';
import 'package:skill_link_gh/widgets/custom_app_toast.dart';
import 'package:url_launcher/url_launcher.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen>
    with WidgetsBindingObserver {
  String? _pendingReference;
  bool _awaitingReturn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _awaitingReturn &&
        _pendingReference != null) {
      _verifyTopUp(_pendingReference!);
    }
  }

  Future<void> _showTopUpSheet() async {
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 6.w,
          right: 6.w,
          top: 3.h,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 3.h,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Top Up Wallet',
                style: Theme.of(
                  ctx,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 0.5.h),
              Text(
                'Enter the amount you want to add (GHS)',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 2.h),
              // Quick amount chips
              Wrap(
                spacing: 8,
                children: [20, 50, 100, 200, 500].map((amt) {
                  return ActionChip(
                    label: Text('GHS $amt'),
                    onPressed: () {
                      amountController.text = '$amt';
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: 2.h),
              TextFormField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Amount (GHS)',
                  prefixText: 'GHS ',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final val = double.tryParse(v ?? '');
                  if (val == null || val < 1) return 'Enter a valid amount';
                  return null;
                },
              ),
              SizedBox(height: 2.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final amount = double.parse(amountController.text);
                    Navigator.pop(ctx);
                    await _initiateTopUp(amount);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.8.h),
                  ),
                  child: const Text('Proceed to Payment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _initiateTopUp(double amount) async {
    try {
      final result = await ref
          .read(walletNotifierProvider.notifier)
          .initiateTopUp(amount);

      final url = result['paymentUrl'] as String?;
      final reference = result['reference'] as String?;

      if (url == null || reference == null) {
        if (mounted) {
          AppToast.show(
            context,
            message: 'Could not initiate payment',
            type: ToastType.error,
          );
        }
        return;
      }

      _pendingReference = reference;
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        setState(() => _awaitingReturn = true);
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, message: 'Error: $e', type: ToastType.error);
      }
    }
  }

  Future<void> _verifyTopUp(String reference) async {
    setState(() => _awaitingReturn = false);
    final success = await ref
        .read(walletNotifierProvider.notifier)
        .verifyTopUp(reference);

    if (!mounted) return;
    AppToast.show(
      context,
      message: success
          ? 'Wallet topped up successfully!'
          : 'Payment not confirmed. Try again.',
      type: success ? ToastType.success : ToastType.error,
    );
    _pendingReference = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final walletState = ref.watch(walletNotifierProvider);

    return Scaffold(
      appBar: CustomAppBar(title: 'My Wallet', variant: AppBarVariant.standard),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(walletNotifierProvider.notifier).loadTransactions(),
        child: CustomScrollView(
          slivers: [
            // Balance card
            SliverToBoxAdapter(
              child: _BalanceCard(
                balance: walletState.balance,
                isProcessing: walletState.isProcessing,
                onTopUp: _showTopUpSheet,
              ),
            ),

            // Pending verification banner
            if (_awaitingReturn)
              SliverToBoxAdapter(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Waiting for payment confirmation...',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      TextButton(
                        onPressed: () => _verifyTopUp(_pendingReference!),
                        child: const Text('Check now'),
                      ),
                    ],
                  ),
                ),
              ),

            // Transactions header
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(4.w, 3.h, 4.w, 1.h),
                child: Text(
                  'Transaction History',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            // Transactions list
            if (walletState.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (walletState.transactions.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.4,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'No transactions yet',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _TransactionTile(tx: walletState.transactions[i]),
                  childCount: walletState.transactions.length,
                ),
              ),

            SliverToBoxAdapter(child: SizedBox(height: 4.h)),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double balance;
  final bool isProcessing;
  final VoidCallback onTopUp;

  const _BalanceCard({
    required this.balance,
    required this.isProcessing,
    required this.onTopUp,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Balance',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          SizedBox(height: 0.8.h),
          Text(
            'GHS ${NumberFormat('#,##0.00').format(balance)}',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 3.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isProcessing ? null : onTopUp,
              icon: isProcessing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add, size: 18),
              label: Text(isProcessing ? 'Processing...' : 'Top Up'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: theme.colorScheme.primary,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final WalletTransaction tx;

  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCredit =
        tx.type == TransactionType.topUp || tx.type == TransactionType.refund;
    final amountColor = isCredit ? Colors.green[600]! : theme.colorScheme.error;
    final amountPrefix = isCredit ? '+' : '-';

    IconData icon;
    switch (tx.type) {
      case TransactionType.topUp:
        icon = Icons.arrow_downward_rounded;
        break;
      case TransactionType.payment:
        icon = Icons.arrow_upward_rounded;
        break;
      case TransactionType.refund:
        icon = Icons.replay_rounded;
        break;
    }

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: amountColor.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: amountColor, size: 20),
      ),
      title: Text(
        tx.description,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        DateFormat('MMM d, yyyy · h:mm a').format(tx.createdAt),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$amountPrefix GHS ${NumberFormat('#,##0.00').format(tx.amount)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: amountColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          _StatusBadge(status: tx.status),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final TransactionStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color color;
    String label;

    switch (status) {
      case TransactionStatus.success:
        color = Colors.green;
        label = 'Success';
        break;
      case TransactionStatus.pending:
        color = Colors.orange;
        label = 'Pending';
        break;
      case TransactionStatus.failed:
        color = theme.colorScheme.error;
        label = 'Failed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
