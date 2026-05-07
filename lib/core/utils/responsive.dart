import 'package:flutter/widgets.dart';

/// Tailwind-style breakpoints. Used as a single source of truth so dashboards,
/// tables, and forms behave consistently across screens.
class Breakpoints {
  static const double xs = 360; // very small phones
  static const double sm = 480; // standard phones
  static const double md = 760; // large phones / small tablets
  static const double lg = 1024; // tablets / small desktop
  static const double xl = 1280; // desktop
}

extension ResponsiveContext on BuildContext {
  Size get _size => MediaQuery.sizeOf(this);
  double get screenWidth => _size.width;

  bool get isMobile => screenWidth < Breakpoints.md;
  bool get isTablet =>
      screenWidth >= Breakpoints.md && screenWidth < Breakpoints.lg;
  bool get isDesktop => screenWidth >= Breakpoints.lg;
  bool get isCompact => screenWidth < Breakpoints.sm;

  /// Pick the value that matches the current breakpoint. Always falls back
  /// to [base] if a more-specific value is not provided. Order: xl > lg >
  /// md > sm > base.
  T responsive<T>({
    required T base,
    T? sm,
    T? md,
    T? lg,
    T? xl,
  }) {
    final w = screenWidth;
    if (w >= Breakpoints.xl && xl != null) return xl;
    if (w >= Breakpoints.lg && lg != null) return lg;
    if (w >= Breakpoints.md && md != null) return md;
    if (w >= Breakpoints.sm && sm != null) return sm;
    return base;
  }

  /// Number of columns in a typical KPI grid for the current breakpoint.
  int get kpiColumns => responsive(base: 1, sm: 2, md: 2, lg: 4);

  /// Default content padding (horizontal) for a screen body.
  double get pagePaddingX => responsive(base: 14.0, sm: 16.0, md: 22.0, lg: 28.0);
}
