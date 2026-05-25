import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/page_chrome.dart';
import '../../../core/widgets/status_pill.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(notificationProvider).fetchNotifications());
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(notificationProvider);

    if (provider.isLoading && provider.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final unread = provider.notifications.where((item) => !item.isRead).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHero(
          title: 'Notifications',
          subtitle:
              'Audit reminders, overdue alerts, and release updates grouped into one inbox.',
          icon: Icons.notifications_none_rounded,
          action: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$unread unread',
              style: AppTextStyles.medium14.copyWith(color: AppColors.white),
            ),
          ),
        ),
        const SizedBox(height: 16),
        AppPanel(
          title: 'Inbox',
          icon: Icons.inbox_outlined,
          child: provider.notifications.isEmpty
              ? (provider.error != null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          Icon(Icons.cloud_off_rounded,
                              color: AppColors.danger, size: 32),
                          const SizedBox(height: 10),
                          Text(
                            "Couldn't load notifications. Check your "
                            'connection and try again.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.body13,
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () => ref
                                .read(notificationProvider)
                                .fetchNotifications(),
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : const EmptyPanel(message: 'No notifications yet.'))
              : Column(
                  children: provider.notifications.map((item) {
                    final color = _colorForType(item.type);
                    return InkWell(
                      onTap: () async {
                        try {
                          await ref
                              .read(notificationProvider)
                              .markAsRead(item.id);
                        } catch (e) {
                          if (!context.mounted) return;
                          AppHelpers.showErrorSnackbar(
                            context,
                            AppHelpers.readableError(e),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: item.isRead ? AppColors.white : AppColors.blueTint,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: item.isRead
                                ? AppColors.border
                                : AppColors.primary.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(_iconForType(item.type), color: color),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.title, style: AppTextStyles.medium14),
                                  const SizedBox(height: 4),
                                  Text(item.body, style: AppTextStyles.body12),
                                  const SizedBox(height: 7),
                                  Text(
                                    AppDateUtils.formatRelative(item.createdAt),
                                    style: AppTextStyles.body11,
                                  ),
                                ],
                              ),
                            ),
                            if (!item.isRead) ...[
                              const SizedBox(width: 12),
                              StatusPill(status: _statusLabel(item.type)),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Color _colorForType(String type) {
    switch (type) {
      case AppConstants.notificationReminder:
        return AppColors.warning;
      case AppConstants.notificationSuccess:
        return AppColors.success;
      case AppConstants.notificationOverdue:
        return AppColors.danger;
      default:
        return AppColors.primary;
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case AppConstants.notificationReminder:
        return Icons.schedule_outlined;
      case AppConstants.notificationSuccess:
        return Icons.check_circle_outline;
      case AppConstants.notificationOverdue:
        return Icons.error_outline;
      default:
        return Icons.email_outlined;
    }
  }

  String _statusLabel(String type) {
    switch (type) {
      case AppConstants.notificationReminder:
        return 'Reminder';
      case AppConstants.notificationOverdue:
        return 'Overdue';
      default:
        return 'New';
    }
  }
}
