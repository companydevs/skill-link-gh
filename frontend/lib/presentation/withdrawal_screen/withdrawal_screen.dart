import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';
import 'package:skill_link_gh/notifier/wallet_notifier.dart';
import 'package:skill_link_gh/provider/wallet_provider.dart';
import 'package:skill_link_gh/widgets/custom_app_bar.dart';
import 'package:skill_link_gh/widgets/custom_app_toast.dart';

class WithdrawalScreen extends ConsumerStatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  ConsumerState<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends ConsumerState<WithdrawalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Shared
  final _amountCtrl = TextEditingController();
  final _accountNameCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  bool _isLoading = false;

  // Mobile money
  String _selectedNetwork = 'MTN';
  final _networks = ['MTN', 'Vodafone', 'AirtelTigo'];

  // Bank transfer
  String? _selectedBankCode;
  String? _selectedBankName;
  final _banks = [
    {'name': 'GCB Bank', 'code': 'GCB'},
    {'name': 'Ecobank Ghana', 'code': 'ECO'},
    {'name': 'Absa Bank Ghana', 'code': 'ABSA'},
    {'name': 'Stanbic Bank', 'code': 'STANBIC'},
    {'name': 'Fidelity Bank', 'code': 'FID'},
    {'name': 'Zenith Bank', 'code': 'ZEN'},
    {'name': 'Access Bank', 'code': 'ACCESS'},
    {'name': 'CalBank', 'code': 'CAL'},
    {'name': 'UBA Ghana', 'code': 'UBA'},
    {'name': 'Republic Bank', 'code': 'REP'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountCtrl.dispose();
    _accountNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    final balance = ref.read(walletNotifierProvider).balance;

    if (amount > balance) {
      AppToast.show(
        context,
        message:
            'Insufficient balance. Available: GHS ${balance.toStringAsFixed(2)}',
        type: ToastType.error,
      );
      return;
    }

    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Withdrawal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ConfirmRow(
              label: 'Amount',
              value: 'GHS ${amount.toStringAsFixed(2)}',
            ),
            _ConfirmRow(
              label: 'Method',
              value: _tabController.index == 0
                  ? 'Mobile Money ($_selectedNetwork)'
                  : 'Bank Transfer ($_selectedBankName)',
            ),
            _ConfirmRow(label: 'Account', value: _accountNumberCtrl.text),
            _ConfirmRow(label: 'Name', value: _accountNameCtrl.text),
            const SizedBox(height: 8),
            Text(
              'Processing time: 1–3 business days',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(walletRepositoryProvider);
      final isMobileMoney = _tabController.index == 0;

      await repo.initiateWithdrawal(
        amount: amount,
        method: isMobileMoney ? 'mobile_money' : 'bank_transfer',
        accountNumber: _accountNumberCtrl.text.trim(),
        accountName: _accountNameCtrl.text.trim(),
        network: isMobileMoney ? _selectedNetwork : null,
        bankCode: isMobileMoney ? null : _selectedBankCode,
        bankName: isMobileMoney ? null : _selectedBankName,
      );

      if (!mounted) return;
      AppToast.show(
        context,
        message:
            'Withdrawal request submitted! Funds will arrive in 1–3 business days.',
        type: ToastType.success,
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      final msg = e
          .toString()
          .replaceAll(RegExp(r'\[.*?\]'), '')
          .replaceAll('Exception:', '')
          .trim();
      AppToast.show(context, message: msg, type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final walletState = ref.watch(walletNotifierProvider);
    final balance = walletState.balance;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Withdraw Funds',
        variant: AppBarVariant.standard,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance card
              _BalanceCard(balance: balance, theme: theme),
              SizedBox(height: 2.5.h),

              // Amount field
              Text(
                'Withdrawal Amount',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 1.h),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  prefixText: 'GHS  ',
                  prefixStyle: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                  hintText: '0.00',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  suffix: TextButton(
                    onPressed: () =>
                        _amountCtrl.text = balance.toStringAsFixed(2),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Max',
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                  ),
                ),
                validator: (v) {
                  final val = double.tryParse(v ?? '');
                  if (val == null || val < 10)
                    return 'Minimum withdrawal is GHS 10';
                  if (val > balance) return 'Exceeds available balance';
                  return null;
                },
              ),

              // Quick amount presets
              SizedBox(height: 1.h),
              Wrap(
                spacing: 8,
                children: [50.0, 100.0, 200.0, 500.0].map((amt) {
                  final enabled = balance >= amt;
                  return GestureDetector(
                    onTap: enabled
                        ? () => _amountCtrl.text = amt.toStringAsFixed(2)
                        : null,
                    child: Chip(
                      label: Text('GHS ${amt.toInt()}'),
                      backgroundColor: enabled
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                      labelStyle: TextStyle(
                        color: enabled
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),

              SizedBox(height: 2.5.h),

              // Method tabs
              Text(
                'Withdrawal Method',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 1.h),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.phone_android_rounded, size: 18),
                      text: 'Mobile Money',
                    ),
                    Tab(
                      icon: Icon(Icons.account_balance_rounded, size: 18),
                      text: 'Bank Transfer',
                    ),
                  ],
                ),
              ),

              SizedBox(height: 2.h),

              // Tab content
              SizedBox(
                height: 28.h,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Mobile Money
                    _MobileMoneyForm(
                      theme: theme,
                      selectedNetwork: _selectedNetwork,
                      networks: _networks,
                      accountNumberCtrl: _accountNumberCtrl,
                      accountNameCtrl: _accountNameCtrl,
                      onNetworkChanged: (v) =>
                          setState(() => _selectedNetwork = v!),
                    ),
                    // Bank Transfer
                    _BankTransferForm(
                      theme: theme,
                      banks: _banks,
                      selectedBankCode: _selectedBankCode,
                      accountNumberCtrl: _accountNumberCtrl,
                      accountNameCtrl: _accountNameCtrl,
                      onBankChanged: (code, name) => setState(() {
                        _selectedBankCode = code;
                        _selectedBankName = name;
                      }),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 1.h),

              // Info note
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.amber,
                      size: 18,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        'Withdrawals are processed within 1–3 business days. '
                        'A processing fee may apply.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 3.h),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.send_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Request Withdrawal',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              SizedBox(height: 4.h),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Balance card ──────────────────────────────────────────────────────────────
class _BalanceCard extends StatelessWidget {
  final double balance;
  final ThemeData theme;
  const _BalanceCard({required this.balance, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Available Balance',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'GHS ${balance.toStringAsFixed(2)}',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Funds available for withdrawal',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white60,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mobile money form ─────────────────────────────────────────────────────────
class _MobileMoneyForm extends StatelessWidget {
  final ThemeData theme;
  final String selectedNetwork;
  final List<String> networks;
  final TextEditingController accountNumberCtrl;
  final TextEditingController accountNameCtrl;
  final ValueChanged<String?> onNetworkChanged;

  const _MobileMoneyForm({
    required this.theme,
    required this.selectedNetwork,
    required this.networks,
    required this.accountNumberCtrl,
    required this.accountNameCtrl,
    required this.onNetworkChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: selectedNetwork,
          decoration: InputDecoration(
            labelText: 'Mobile Network',
            prefixIcon: Icon(
              Icons.signal_cellular_alt_rounded,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: networks
              .map((n) => DropdownMenuItem(value: n, child: Text(n)))
              .toList(),
          onChanged: onNetworkChanged,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: accountNumberCtrl,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'Mobile Number',
            hintText: '024XXXXXXX',
            prefixIcon: Icon(
              Icons.phone_rounded,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Enter mobile number';
            if (v.length < 10) return 'Enter a valid 10-digit number';
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: accountNameCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Account Name',
            hintText: 'Name on the account',
            prefixIcon: Icon(
              Icons.person_outline_rounded,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (v) =>
              v == null || v.isEmpty ? 'Enter account name' : null,
        ),
      ],
    );
  }
}

// ── Bank transfer form ────────────────────────────────────────────────────────
class _BankTransferForm extends StatelessWidget {
  final ThemeData theme;
  final List<Map<String, String>> banks;
  final String? selectedBankCode;
  final TextEditingController accountNumberCtrl;
  final TextEditingController accountNameCtrl;
  final void Function(String? code, String? name) onBankChanged;

  const _BankTransferForm({
    required this.theme,
    required this.banks,
    required this.selectedBankCode,
    required this.accountNumberCtrl,
    required this.accountNameCtrl,
    required this.onBankChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: selectedBankCode,
          decoration: InputDecoration(
            labelText: 'Select Bank',
            prefixIcon: Icon(
              Icons.account_balance_rounded,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: banks
              .map(
                (b) =>
                    DropdownMenuItem(value: b['code'], child: Text(b['name']!)),
              )
              .toList(),
          onChanged: (code) {
            final bank = banks.firstWhere(
              (b) => b['code'] == code,
              orElse: () => {},
            );
            onBankChanged(code, bank['name']);
          },
          validator: (v) => v == null ? 'Select a bank' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: accountNumberCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'Account Number',
            prefixIcon: Icon(
              Icons.credit_card_rounded,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Enter account number';
            if (v.length < 10) return 'Enter a valid account number';
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: accountNameCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Account Name',
            hintText: 'Name on the account',
            prefixIcon: Icon(
              Icons.person_outline_rounded,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (v) =>
              v == null || v.isEmpty ? 'Enter account name' : null,
        ),
      ],
    );
  }
}

// ── Confirm row ───────────────────────────────────────────────────────────────
class _ConfirmRow extends StatelessWidget {
  final String label;
  final String value;
  const _ConfirmRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
