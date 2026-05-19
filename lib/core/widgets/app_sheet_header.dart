import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Header row for modal bottom sheets: a title plus an explicit close (X)
/// button on the right, so every sheet has the same dismiss affordance as
/// the app's dialogs. Drop-in replacement for a sheet's leading title
/// `Text(...)`; it carries no outer padding so it slots into the sheet's
/// existing content padding.
class AppSheetHeader extends StatelessWidget {
  const AppSheetHeader({super.key, required this.title, this.onClose});

  final String title;

  /// Defaults to popping the sheet with no result.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppTextStyles.title18)),
        IconButton(
          tooltip: 'Close',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.close_rounded, size: 20),
          color: AppColors.textSecondary,
          onPressed: onClose ?? () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
