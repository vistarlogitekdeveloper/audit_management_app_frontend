import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'brand.dart';

/// KPI tile: a dark surface card with a tinted icon, a Bricolage hero
/// value, a label, and a soft S-mark corner accent. The optional badge
/// echoes the design system's small status chip used on dashboards.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.value,
    required this.label,
    this.badge,
    this.badgeColor = AppColors.primary,
    this.icon,
    this.tone = AppColors.primary,
  });

  final String value;
  final String label;
  final String? badge;
  final Color badgeColor;
  final IconData? icon;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xB316142A),
            Color(0xB3110F1E),
          ],
        ),
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          const CardCornerS(),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (icon != null)
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: tone.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                              color: tone.withValues(alpha: 0.28)),
                        ),
                        child: Icon(icon, size: 19, color: tone),
                      ),
                    const Spacer(),
                    if (badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: badgeColor.withValues(alpha: 0.32)),
                        ),
                        child: Text(
                          badge!,
                          style: AppTextStyles.medium12.copyWith(
                            color: badgeColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(value, style: AppTextStyles.statValue),
                const SizedBox(height: 6),
                Text(label, style: AppTextStyles.body13),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
