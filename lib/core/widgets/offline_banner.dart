import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: AppColors.warning,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        'You are offline. Some actions may not sync until internet is restored.',
        style: AppTextStyles.body12.copyWith(color: AppColors.white),
      ),
    );
  }
}
