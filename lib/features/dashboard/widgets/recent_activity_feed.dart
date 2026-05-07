import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';

class RecentActivityFeed extends StatelessWidget {
  const RecentActivityFeed({super.key, required this.items});

  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: item['color'] as Color,
                  shape: BoxShape.circle,
                ),
              ),
              title: Text(item['title'] as String, style: AppTextStyles.body13),
              subtitle: Text(item['meta'] as String, style: AppTextStyles.body11),
            ),
          )
          .toList(),
    );
  }
}
