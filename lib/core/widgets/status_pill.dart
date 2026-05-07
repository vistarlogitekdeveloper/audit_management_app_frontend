import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    Color bg = AppColors.greyTint;
    Color fg = AppColors.textSecondary;

    if (normalized.contains('pass') || normalized.contains('completed')) {
      bg = AppColors.greenTint;
      fg = AppColors.success;
    } else if (normalized.contains('fail') || normalized.contains('overdue')) {
      bg = AppColors.redTint;
      fg = AppColors.danger;
    } else if (normalized.contains('review') ||
        normalized.contains('scheduled') ||
        normalized.contains('submitted')) {
      bg = AppColors.blueTint;
      fg = AppColors.primary;
    } else if (normalized.contains('pending') ||
        normalized.contains('assigned') ||
        normalized.contains('warning')) {
      bg = AppColors.amberTint;
      fg = AppColors.warning;
    } else if (normalized.contains('action')) {
      bg = const Color(0xFFF0EAFF);
      fg = AppColors.purple;
    } else if (normalized == AppConstants.resultNA) {
      bg = AppColors.naBackground;
      fg = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: 0.15)),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: AppTextStyles.medium12.copyWith(color: fg),
      ),
    );
  }
}
