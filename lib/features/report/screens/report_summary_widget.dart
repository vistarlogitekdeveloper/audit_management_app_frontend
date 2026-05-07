import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/stat_card.dart';

class ReportSummaryWidget extends StatelessWidget {
  const ReportSummaryWidget({
    super.key,
    required this.total,
    required this.passCount,
    required this.failCount,
    required this.passPercent,
  });

  final int total;
  final int passCount;
  final int failCount;
  final double passPercent;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.7,
      children: [
        StatCard(value: '$total', label: 'Total points audited', badge: 'Total', badgeColor: AppColors.primary),
        StatCard(value: '$passCount', label: 'Pass count', badge: 'Pass', badgeColor: AppColors.success),
        StatCard(value: '$failCount', label: 'Fail count', badge: 'Fail', badgeColor: AppColors.danger),
        StatCard(
          value: '${passPercent.toStringAsFixed(0)}%',
          label: 'Pass %',
          badge: 'Rate',
          badgeColor: passPercent >= 80
              ? AppColors.success
              : passPercent >= 60
                  ? AppColors.warning
                  : AppColors.danger,
        ),
      ],
    );
  }
}
