import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_link_gh/provider/wallet_provider.dart';

/// Wallet-first payment widget.
/// Auto-selects wallet. If balance is insufficient, shows a top-up nudge.
class PaymentMethodWidget extends ConsumerWidget {
  final String? selectedPaymentMethod;
  final Function(String) onPaymentMethodSelected;
  final List<Map<String, dynamic>> savedCards; // kept for API compat, unused
  final double totalAmount;

  const PaymentMethodWidget({
    super.key,
    required this.selectedPaymentMethod,
    required this.onPaymentMethodSelected,
    required this.savedCards,
    this.totalAmount = 0.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final walletState = ref.watch(walletNotifierProvider);
    final balance = walletState.balance;
    final hasSufficient = balance >= totalAmount;
    final isSelected = selectedPaymentMethod == 'wallet';
    final shortfall = totalAmount - balance;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Method',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // ── Wallet tile ──────────────────────────────────────────────
          InkWell(
            onTap: hasSufficient
                ? () => onPaymentMethodSelected('wallet')
                : null,
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF1A73E8).withValues(alpha: 0.08)
                    : theme.colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF1A73E8)
                      : theme.colorScheme.outline.withValues(alpha: 0.25),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A73E8).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Color(0xFF1A73E8),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SkillLink Wallet',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Balance: GH₵ ${balance.toStringAsFixed(2)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: hasSufficient
                                ? const Color(0xFF22C55E)
                                : theme.colorScheme.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF1A73E8),
                      size: 22,
                    ),
                ],
              ),
            ),
          ),

          // ── Insufficient balance nudge ───────────────────────────────
          if (!hasSufficient && totalAmount > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.colorScheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: theme.colorScheme.error,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You need GH₵ ${shortfall.toStringAsFixed(2)} more to complete this booking.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/wallet-screen'),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  'Top Up GH₵ ${shortfall.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1A73E8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
