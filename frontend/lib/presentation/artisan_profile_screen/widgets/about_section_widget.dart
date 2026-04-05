import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AboutSectionWidget extends StatelessWidget {
  final Map<String, dynamic> artisanData;

  const AboutSectionWidget({super.key, required this.artisanData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bio = artisanData['bio'] as String? ?? '';
    final languages = List<String>.from(
      artisanData['languages'] as List? ?? ['English'],
    );
    final certifications = List<String>.from(
      artisanData['certifications'] as List? ?? [],
    );
    final memberSince = artisanData['memberSince'] as String?;

    return ListView(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 12.h),
      children: [
        if (bio.isNotEmpty) ...[
          Text(bio, style: theme.textTheme.bodyMedium?.copyWith(height: 1.6)),
          SizedBox(height: 2.h),
          Divider(color: theme.colorScheme.outline.withValues(alpha: 0.15)),
          SizedBox(height: 1.5.h),
        ],

        // Info rows
        _infoRow(
          context,
          Icons.language_outlined,
          'Languages',
          languages.join(', '),
        ),
        if (memberSince != null)
          _infoRow(
            context,
            Icons.calendar_today_outlined,
            'Member since',
            _formatDate(memberSince),
          ),

        // Certifications
        if (certifications.isNotEmpty) ...[
          SizedBox(height: 2.h),
          Text(
            'Certifications',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          ...certifications.map(
            (c) => Padding(
              padding: EdgeInsets.only(bottom: 0.8.h),
              child: Row(
                children: [
                  Icon(
                    Icons.verified_outlined,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(width: 2.w),
                  Flexible(child: Text(c, style: theme.textTheme.bodySmall)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _infoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          SizedBox(width: 3.w),
          Text(
            '$label: ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      const m = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${m[d.month - 1]} ${d.year}';
    } catch (_) {
      return iso;
    }
  }
}
