import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:skill_link_gh/domain/models/wallet_model.dart';
import 'package:skill_link_gh/provider/wallet_provider.dart';
import 'package:skill_link_gh/widgets/custom_app_toast.dart';
import 'package:url_launcher/url_launcher.dart';

// ─── Palette helpers ────────────────────────────────────────────────────────
const _kBlue1 = Color(0xFF2563EB);
const _kBlue2 = Color(0xFF1D4ED8);
const _kGreen = Color(0xFF10B981);
const _kAmber = Color(0xFFF59E0B);
const _kRed = Color(0xFFEF4444);

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen>
    with WidgetsBindingObserver {
  String? _pendingReference;
  bool _awaitingReturn = false;
  bool _balanceVisible = true;
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _listenForDeepLink();
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  void _listenForDeepLink() {
    final appLinks = AppLinks();
    // Handle link while app is already running (foreground / background)
    _linkSub = appLinks.uriLinkStream.listen((uri) {
      if (uri.scheme == 'skilllink' && uri.host == 'wallet') {
        final ref = uri.queryParameters['reference'] ?? _pendingReference;
        if (ref != null) _verifyTopUp(ref);
      }
    });
    // Handle link that cold-started the app
    appLinks.getInitialLink().then((uri) {
      if (uri != null && uri.scheme == 'skilllink' && uri.host == 'wallet') {
        final ref = uri.queryParameters['reference'] ?? _pendingReference;
        if (ref != null) _verifyTopUp(ref);
      }
    });
  }

  Future<void> _showTopUpSheet() async {
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    int? selectedPreset;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 6.w,
            right: 6.w,
            top: 2.h,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 3.h,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // drag handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      ctx,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _kBlue1.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: _kBlue1,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Top Up Wallet',
                          style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Secure payment via Paystack',
                          style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                            color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 2.5.h),
                // preset amounts
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.4,
                  children: [20, 50, 100, 200, 500, 1000].map((amt) {
                    final selected = selectedPreset == amt;
                    return GestureDetector(
                      onTap: () {
                        setSheet(() => selectedPreset = amt);
                        amountController.text = '$amt';
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          color: selected
                              ? _kBlue1
                              : _kBlue1.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? _kBlue1
                                : _kBlue1.withValues(alpha: 0.2),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'GHS $amt',
                          style: TextStyle(
                            color: selected ? Colors.white : _kBlue1,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
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
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  onChanged: (_) => setSheet(() => selectedPreset = null),
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Custom amount',
                    prefixText: 'GHS  ',
                    prefixStyle: const TextStyle(
                      color: _kBlue1,
                      fontWeight: FontWeight.w600,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: Theme.of(
                          ctx,
                        ).colorScheme.outline.withValues(alpha: 0.4),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _kBlue1, width: 2),
                    ),
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
                      backgroundColor: _kBlue1,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 1.8.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Proceed to Payment',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: RefreshIndicator(
        color: _kBlue1,
        onRefresh: () =>
            ref.read(walletNotifierProvider.notifier).loadTransactions(),
        child: CustomScrollView(
          slivers: [
            // ── Custom SliverAppBar ──────────────────────────────────
            SliverAppBar(
              expandedHeight: 26.h,
              pinned: true,
              backgroundColor: _kBlue2,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'My Wallet',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: _WalletHeroCard(
                  balance: walletState.balance,
                  onHoldBalance: walletState.onHoldBalance,
                  isProcessing: walletState.isProcessing,
                  balanceVisible: _balanceVisible,
                  onToggleVisibility: () =>
                      setState(() => _balanceVisible = !_balanceVisible),
                  onTopUp: _showTopUpSheet,
                  isDark: isDark,
                ),
              ),
            ),

            // ── Pending verification banner ──────────────────────────
            if (_awaitingReturn)
              SliverToBoxAdapter(
                child: _PendingBanner(
                  onCheck: () => _verifyTopUp(_pendingReference!),
                ),
              ),

            // ── Quick stats row ──────────────────────────────────────
            SliverToBoxAdapter(
              child: _QuickStats(transactions: walletState.transactions),
            ),

            // ── Section header ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 0.5.h),
                child: Row(
                  children: [
                    Text(
                      'Transactions',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    if (walletState.transactions.isNotEmpty)
                      Text(
                        '${walletState.transactions.length} total',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Transactions ─────────────────────────────────────────
            if (walletState.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: _kBlue1)),
              )
            else if (walletState.transactions.isEmpty)
              SliverFillRemaining(child: _EmptyTransactions(theme: theme))
            else
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((ctx, i) {
                    final tx = walletState.transactions[i];
                    final prev = i > 0 ? walletState.transactions[i - 1] : null;
                    final showDate =
                        prev == null || !_sameDay(prev.createdAt, tx.createdAt);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showDate) _DateDivider(date: tx.createdAt),
                        _TransactionCard(tx: tx),
                      ],
                    );
                  }, childCount: walletState.transactions.length),
                ),
              ),

            SliverToBoxAdapter(child: SizedBox(height: 4.h)),
          ],
        ),
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ─── Hero balance card (inside FlexibleSpaceBar) ────────────────────────────
class _WalletHeroCard extends StatelessWidget {
  final double balance;
  final double onHoldBalance;
  final bool isProcessing;
  final bool balanceVisible;
  final VoidCallback onToggleVisibility;
  final VoidCallback onTopUp;
  final bool isDark;

  const _WalletHeroCard({
    required this.balance,
    required this.onHoldBalance,
    required this.isProcessing,
    required this.balanceVisible,
    required this.onToggleVisibility,
    required this.onTopUp,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E40AF), _kBlue1, Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(5.w, 7.h, 5.w, 2.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Available Balance',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onToggleVisibility,
                    child: Icon(
                      balanceVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: balanceVisible
                    ? Text(
                        'GHS ${NumberFormat('#,##0.00').format(balance)}',
                        key: const ValueKey('visible'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      )
                    : Text(
                        'GHS ••••••',
                        key: const ValueKey('hidden'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
              ),
              // On-hold balance chip (only shown when > 0)
              if (onHoldBalance > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.lock_clock,
                        color: Colors.white70,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'GHS ${NumberFormat('#,##0.00').format(onHoldBalance)} on hold',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
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
                            color: _kBlue1,
                          ),
                        )
                      : const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    isProcessing ? 'Processing...' : 'Top Up Wallet',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _kBlue1,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Pending banner ──────────────────────────────────────────────────────────
class _PendingBanner extends StatelessWidget {
  final VoidCallback onCheck;
  const _PendingBanner({required this.onCheck});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0),
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: _kAmber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kAmber.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: _kAmber),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Waiting for payment confirmation...',
              style: TextStyle(
                color: _kAmber,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            onPressed: onCheck,
            style: TextButton.styleFrom(foregroundColor: _kAmber),
            child: const Text(
              'Check now',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick stats ─────────────────────────────────────────────────────────────
class _QuickStats extends StatelessWidget {
  final List<WalletTransaction> transactions;
  const _QuickStats({required this.transactions});

  @override
  Widget build(BuildContext context) {
    double totalIn = 0, totalOut = 0;
    for (final tx in transactions) {
      if (tx.status == TransactionStatus.success) {
        if (tx.type == TransactionType.topUp ||
            tx.type == TransactionType.refund) {
          totalIn += tx.amount;
        } else if (tx.type == TransactionType.payment) {
          totalOut += tx.amount;
        }
        // onHold is excluded from both totals until released
      }
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
      child: Row(
        children: [
          _StatChip(
            label: 'Total In',
            value: 'GHS ${NumberFormat('#,##0').format(totalIn)}',
            color: _kGreen,
            icon: Icons.arrow_downward_rounded,
          ),
          SizedBox(width: 3.w),
          _StatChip(
            label: 'Total Out',
            value: 'GHS ${NumberFormat('#,##0').format(totalOut)}',
            color: _kRed,
            icon: Icons.arrow_upward_rounded,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Date divider ────────────────────────────────────────────────────────────
class _DateDivider extends StatelessWidget {
  final DateTime date;
  const _DateDivider({required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    String label;
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      label = 'Today';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      label = 'Yesterday';
    } else {
      label = DateFormat('MMMM d, yyyy').format(date);
    }

    return Padding(
      padding: EdgeInsets.only(top: 2.h, bottom: 0.8.h),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── Transaction card ────────────────────────────────────────────────────────
class _TransactionCard extends StatelessWidget {
  final WalletTransaction tx;
  const _TransactionCard({required this.tx});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCredit =
        tx.type == TransactionType.topUp || tx.type == TransactionType.refund;
    final isOnHold = tx.type == TransactionType.onHold;
    final color = isOnHold ? _kAmber : (isCredit ? _kGreen : _kRed);
    final prefix = isOnHold ? '⏳' : (isCredit ? '+' : '-');

    IconData icon;
    String typeLabel;
    switch (tx.type) {
      case TransactionType.topUp:
        icon = Icons.arrow_downward_rounded;
        typeLabel = 'Top Up';
        break;
      case TransactionType.payment:
        icon = Icons.arrow_upward_rounded;
        typeLabel = 'Payment';
        break;
      case TransactionType.refund:
        icon = Icons.replay_rounded;
        typeLabel = 'Refund';
        break;
      case TransactionType.onHold:
        icon = Icons.lock_clock;
        typeLabel = 'On Hold';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.symmetric(horizontal: 3.5.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    _StatusDot(status: tx.status),
                    const SizedBox(width: 5),
                    Text(
                      DateFormat('h:mm a').format(tx.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$prefix GHS ${NumberFormat('#,##0.00').format(tx.amount)}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                typeLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final TransactionStatus status;
  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case TransactionStatus.success:
        color = _kGreen;
        label = 'Success';
        break;
      case TransactionStatus.pending:
        color = _kAmber;
        label = 'Pending';
        break;
      case TransactionStatus.failed:
        color = _kRed;
        label = 'Failed';
        break;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Empty state ─────────────────────────────────────────────────────────────
class _EmptyTransactions extends StatelessWidget {
  final ThemeData theme;
  const _EmptyTransactions({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _kBlue1.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 36,
              color: _kBlue1,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Top up your wallet to get started',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
