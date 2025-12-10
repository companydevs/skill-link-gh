import 'package:flutter/material.dart';

/// Widget displaying pricing breakdown
class PricingSummaryWidget extends StatelessWidget {
  final Map<String, dynamic> pricingData;

  const PricingSummaryWidget({
    super.key,
    required this.pricingData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            'Pricing Summary',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildPriceRow(
            context,
            'Base Service Fee',
            pricingData['basePrice'] as String,
          ),
          const SizedBox(height: 8),
          _buildPriceRow(
            context,
            'Service Complexity',
            pricingData['complexityFee'] as String,
          ),
          const SizedBox(height: 8),
          _buildPriceRow(
            context,
            'Travel Distance',
            pricingData['travelFee'] as String,
          ),
          const SizedBox(height: 8),
          _buildPriceRow(
            context,
            'Platform Fee',
            pricingData['platformFee'] as String,
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
                pricingData['totalPrice'] as String,
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

  Widget _buildPriceRow(BuildContext context, String label, String amount) {
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
        Text(
          amount,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
