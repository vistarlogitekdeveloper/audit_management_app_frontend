import 'package:intl/intl.dart';

class AppDateUtils {
  static final DateFormat _displayFormat = DateFormat('MMM d, yyyy');
  static final DateFormat _apiFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _timeFormat = DateFormat('h:mm a');

  /// Format a DateTime to display format: "May 2, 2025"
  static String formatDisplay(DateTime date) => _displayFormat.format(date);

  /// Format a DateTime to API format: "2025-05-02"
  static String formatApi(DateTime date) => _apiFormat.format(date);

  /// Parse an API date string to DateTime
  static DateTime? parseApi(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr).toLocal();
    } catch (_) {
      return null;
    }
  }

  /// Format to relative time: "Today 9:14 AM", "Yesterday", "Apr 28"
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);

    if (dateDay == today) {
      return 'Today ${_timeFormat.format(date)}';
    } else if (dateDay == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  /// Days remaining from now to a target date
  static int daysRemaining(DateTime target) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(target.year, target.month, target.day);
    return end.difference(today).inDays;
  }

  /// Whether a date is in the future
  static bool isFuture(DateTime date) {
    final today = DateTime.now();
    return date.isAfter(DateTime(today.year, today.month, today.day));
  }

  /// Calculate action plan deadline (auditDate + 8 days)
  static DateTime actionPlanDeadline(DateTime auditDate) =>
      auditDate.add(const Duration(days: 8));

  static DateTime normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
