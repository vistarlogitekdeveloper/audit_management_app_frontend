import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/status_pill.dart';

class UpcomingAuditsList extends StatelessWidget {
  const UpcomingAuditsList({super.key, required this.items});

  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: item['color'] as Color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['project'] as String, style: AppTextStyles.medium14),
                        const SizedBox(height: 4),
                        Text(
                          '${item['auditor']} + ${item['cluster']}',
                          style: AppTextStyles.body12,
                        ),
                        const SizedBox(height: 4),
                        Text(item['date'] as String, style: AppTextStyles.body11),
                      ],
                    ),
                  ),
                  StatusPill(status: item['status'] as String),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
