import 'package:flutter/material.dart';

class PricingSummaryWidget extends StatelessWidget {
  final Map<String, dynamic> pricingData;

  const PricingSummaryWidget({super.key, required this.pricingData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isContract = pricingData['isContract'] as bool? ?? false;

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
          Row(
            children: [
              Text(
                'Pricing Summary',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isContract
                      ? theme.colorScheme.secondaryContainer
                      : theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isContract ? 'Contract' : 'Daily Rate',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isContract
                        ? theme.colorScheme.onSecondaryContainer
                        : theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _row(
            context,
            isContract ? 'Contract Price' : 'Daily Rate',
            pricingData['basePrice'] as String? ?? '—',
          ),
          if (pricingData['travelFee'] != null) ...[
            const SizedBox(height: 8),
            _row(context, 'Travel Fee', pricingData['travelFee'] as String),
          ],
          const SizedBox(height: 8),
          _row(
            context,
            'Platform Fee (5%)',
            pricingData['platformFee'] as String? ?? '—',
          ),
          const SizedBox(height: 12),
          Divider(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            thickness: 1,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                pricingData['totalPrice'] as String? ?? 'TBD',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String amount) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Flexible(
          child: Text(
            amount,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
