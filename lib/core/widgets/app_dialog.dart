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
    this.compact = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;

  /// The action row/button(s) shown below the message.
  final Widget actions;

  /// Defaults to popping the dialog with no result.
  final VoidCallback? onClose;

  /// Use a tighter layout — smaller icon, smaller title, less padding and a
  /// narrower max width. Suited to short confirm-style dialogs (e.g. the
  /// "Audit Plan Released" toast that just needs two action buttons), so
  /// they don't feel oversized on a wide laptop viewport.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final padding = compact
        ? const EdgeInsets.fromLTRB(20, 24, 20, 20)
        : const EdgeInsets.fromLTRB(24, 32, 24, 24);
    final iconSize = compact ? 56.0 : 72.0;
    final iconGlyphSize = compact ? 28.0 : 38.0;
    final titleStyle =
        compact ? AppTextStyles.title18 : AppTextStyles.headline22;
    final iconToTitleGap = compact ? 14.0 : 20.0;
    final messageToActionsGap = compact ? 20.0 : 28.0;
    final maxWidth = compact ? 380.0 : 560.0;
    final closeOffset = compact ? 4.0 : 6.0;
    final closeIconSize = compact ? 18.0 : 20.0;

    return Dialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      // Reduce the screen-edge inset on compact so the narrower card still
      // centres cleanly on small screens without hugging the edges.
      insetPadding: EdgeInsets.symmetric(
        horizontal: compact ? 24 : 40,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.line),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Stack(
          children: [
            Padding(
              padding: padding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: iconColor.withValues(alpha: 0.36)),
                    ),
                    child: Icon(icon, color: iconColor, size: iconGlyphSize),
                  ),
                  SizedBox(height: iconToTitleGap),
                  Text(
                    title,
                    style: titleStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    style: AppTextStyles.body14
                        .copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: messageToActionsGap),
                  actions,
                ],
              ),
            ),
            Positioned(
              top: closeOffset,
              right: closeOffset,
              child: IconButton(
                tooltip: 'Close',
                icon: Icon(Icons.close_rounded, size: closeIconSize),
                color: AppColors.textSecondary,
                onPressed: onClose ?? () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
