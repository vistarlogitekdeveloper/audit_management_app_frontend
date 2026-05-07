import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';

class AppHelpers {
  static String getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  static Color avatarColorByRole(String role) {
    switch (role) {
      case AppConstants.roleAdmin:
        return AppColors.primary;
      case AppConstants.roleAuditor:
        return AppColors.secondary;
      case AppConstants.roleProjectOwner:
        return AppColors.warning;
      case AppConstants.roleClusterManager:
        return AppColors.purple;
      default:
        return AppColors.textSecondary;
    }
  }

  static String roleLabel(String role) {
    switch (role) {
      case AppConstants.roleAdmin:
        return 'Admin';
      case AppConstants.roleAuditor:
        return 'Auditor';
      case AppConstants.roleProjectOwner:
        return 'Owner';
      case AppConstants.roleClusterManager:
        return 'Cluster Manager';
      default:
        return role;
    }
  }

  static Color passPercentColor(double percent) {
    if (percent >= 80) return AppColors.success;
    if (percent >= 60) return AppColors.warning;
    return AppColors.danger;
  }

  static void showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static double calcPassPercent(int pass, int total) {
    if (total == 0) return 0;
    return (pass / total) * 100;
  }

  static String formatPercent(double value) => '${value.toStringAsFixed(0)}%';

  static String formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  static Future<bool> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    Color? confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: confirmColor ?? AppColors.primary,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Safely coerces a JSON value (num or numeric String) to double.
  /// Postgres DECIMAL columns serialize as Strings via Sequelize so plain
  /// `value as num?` casts blow up at runtime.
  static double parseDouble(Object? value, {double fallback = 0.0}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  /// Same idea as [parseDouble] but returns int.
  static int parseInt(Object? value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? fallback;
    }
    return fallback;
  }

  static String readableError(Object error) {
    final text = error.toString();
    if (text.toLowerCase().contains('socket') ||
        text.toLowerCase().contains('network')) {
      return 'No internet connection. Please try again.';
    }
    return text.replaceFirst('Exception: ', '');
  }
}
