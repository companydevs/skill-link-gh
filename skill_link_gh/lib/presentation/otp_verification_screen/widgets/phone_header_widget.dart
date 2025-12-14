import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Header widget displaying phone number with edit option
class PhoneHeaderWidget extends StatelessWidget {
  final String phoneNumber;
  final VoidCallback onEdit;

  const PhoneHeaderWidget({
    super.key,
    required this.phoneNumber,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          'Verify Your Phone Number',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Code sent to ',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              phoneNumber,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: CustomIconWidget(
                  iconName: 'edit',
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
