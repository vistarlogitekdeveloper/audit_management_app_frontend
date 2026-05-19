import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';

class AppHelpers {
  static String getInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
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
        title: Row(
          children: [
            Expanded(child: Text(title)),
            IconButton(
              tooltip: 'Close',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.close_rounded, size: 20),
              color: AppColors.textSecondary,
              // Dismissing a confirmation == cancel.
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
        content: Text(message),
        // The global filledButtonTheme forces full-width buttons
        // (Size.fromHeight = infinite width), which makes the default
        // actions OverflowBar stack/misalign. Lay the actions out
        // explicitly as two equal-width buttons on one row instead.
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(cancelLabel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: confirmColor ?? AppColors.primary,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(confirmLabel),
                ),
              ),
            ],
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

  /// Safely coerces a decoded-JSON value to `Map<String, dynamic>`.
  ///
  /// Returns `null` when [value] is not a map (e.g. the backend sent a plain
  /// string/id instead of an embedded association). This avoids the
  /// `type 'String' is not a subtype of type 'Map<String, dynamic>'` crashes
  /// that hard `as Map<String, dynamic>` casts throw.
  static Map<String, dynamic>? asStringMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  /// Maps a decoded-JSON list of objects into models, skipping any element
  /// that is not a map instead of throwing on the first bad element.
  static List<T> mapList<T>(
    Object? value,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (value is! List) return <T>[];
    return value
        .whereType<Map>()
        .map((item) => fromJson(Map<String, dynamic>.from(item)))
        .toList();
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
