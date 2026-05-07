class Validators {
  static final RegExp _emailRegex =
      RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$');

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? validateRequired(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validateFutureDate(DateTime? value) {
    if (value == null) return 'Date is required';
    if (!value.isAfter(DateTime.now())) {
      return 'Date must be in the future';
    }
    return null;
  }

  static String? validateWithinDays(DateTime? value, int days, DateTime from) {
    if (value == null) return 'Date is required';
    final deadline = from.add(Duration(days: days));
    if (value.isAfter(deadline)) {
      return 'Date must be within $days days';
    }
    return null;
  }

  static String? validateSelection(String? value, {String fieldName = 'Selection'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}
