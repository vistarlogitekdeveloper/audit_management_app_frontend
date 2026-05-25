import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Status pill — translucent dark tint + a colored leading dot.
/// Each pill is keyed off the normalized status text so the color
/// family lines up with our success/warning/info/danger scale.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});

  final String status;

  _PillStyle _styleFor(String s) {
    if (s.contains('pass') || s.contains('completed') || s.contains('approved') || s.contains('closed')) {
      return _PillStyle(AppColors.greenTint, AppColors.success);
    }
    if (s.contains('fail') || s.contains('overdue') || s.contains('reject')) {
      return _PillStyle(AppColors.redTint, AppColors.danger);
    }
    if (s.contains('review') || s.contains('scheduled') || s.contains('submitted')) {
      return _PillStyle(AppColors.blueTint, AppColors.info);
    }
    if (s.contains('pending') || s.contains('assigned') || s.contains('warning') || s.contains('progress')) {
      return _PillStyle(AppColors.amberTint, AppColors.warning);
    }
    if (s.contains('action')) {
      return _PillStyle(
        AppColors.ribbonViolet.withValues(alpha: 0.18),
        AppColors.ribbonViolet,
      );
    }
    if (s.contains('draft')) {
      return _PillStyle(
        AppColors.ribbonPink.withValues(alpha: 0.16),
        AppColors.ribbonPink,
      );
    }
    if (s == AppConstants.resultNA.toLowerCase()) {
      return _PillStyle(AppColors.naBackground, AppColors.textSecondary);
    }
    return _PillStyle(AppColors.greyTint, AppColors.textSecondary);
  }

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final style = _styleFor(normalized);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: style.fg.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: style.fg,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: style.fg.withValues(alpha: 0.55),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Text(
            status.replaceAll('_', ' '),
            style: AppTextStyles.medium12.copyWith(
              color: style.fg,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _PillStyle {
  const _PillStyle(this.bg, this.fg);
  final Color bg;
  final Color fg;
}
