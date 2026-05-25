import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Shared modal shell for success / info dialogs: a rounded card with a
/// circular icon, title, message, caller-supplied [actions], and a
/// consistent top-right close (X) button so the window can always be
/// dismissed (matches the close affordance used across the app).
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.actions,
    this.iconColor = AppColors.primary,
    this.onClose,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;

  /// The action row/button(s) shown below the message.
  final Widget actions;

  /// Defaults to popping the dialog with no result.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.line),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: iconColor.withValues(alpha: 0.36)),
                  ),
                  child: Icon(icon, color: iconColor, size: 38),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: AppTextStyles.headline22,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: AppTextStyles.body14
                      .copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                actions,
              ],
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: IconButton(
              tooltip: 'Close',
              icon: const Icon(Icons.close_rounded, size: 20),
              color: AppColors.textSecondary,
              onPressed: onClose ?? () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
