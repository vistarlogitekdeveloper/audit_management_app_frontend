import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.value,
    required this.label,
    this.badge,
    this.badgeColor = AppColors.primary,
  });

  final String value;
  final String label;
  final String? badge;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge!,
                  style: AppTextStyles.medium12.copyWith(color: badgeColor),
                ),
              )
            else
              const SizedBox(height: 24),
            const SizedBox(height: 18),
            Text(value, style: AppTextStyles.statValue),
            const SizedBox(height: 8),
            Text(label, style: AppTextStyles.body13),
          ],
        ),
      ),
    );
  }
}
