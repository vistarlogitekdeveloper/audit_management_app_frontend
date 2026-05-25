import 'package:flutter/material.dart';

/// Vistar Premium design tokens — supports both **dark** and **light**
/// modes. The signature ribbon palette (the rainbow swoosh) is the
/// brand identity and stays constant across modes; surfaces, lines,
/// text, and semantic status colors flip based on [appBrightness].
///
/// Most call-sites read `AppColors.background`, `AppColors.surface`,
/// `AppColors.danger`, etc. — those are mode-aware static getters that
/// re-resolve every build. The few brand stops that never change
/// (ribbon hues, ribbon stops, white, black) remain `static const` so
/// they can be used in `const` constructors (e.g. theme construction).
///
/// To toggle modes at runtime, mutate [appBrightness] via
/// `ThemeController` — every widget rebuild after the mutation reads
/// fresh values.

/// Global brightness used by the mode-aware getters below. Defaults to
/// dark to match the launch experience; `ThemeController` restores the
/// persisted preference on app start and writes through to this
/// notifier when the user toggles.
final ValueNotifier<Brightness> appBrightness =
    ValueNotifier<Brightness>(Brightness.dark);

bool get _isDark => appBrightness.value == Brightness.dark;

class AppColors {
  // ════════════════════════════════════════════════════════════════
  // BRAND-INVARIANT (always const — safe for const constructors)
  // ════════════════════════════════════════════════════════════════

  // ── Brand ribbon stops (the rainbow swoosh) ─────────────────────
  static const Color ribbonPurple   = Color(0xFF7A1FB0);
  static const Color ribbonViolet   = Color(0xFF9B30C9);
  static const Color ribbonMagenta  = Color(0xFFC018C0);
  static const Color ribbonPink     = Color(0xFFE0218A);
  static const Color ribbonRed      = Color(0xFFC8102E);
  static const Color ribbonOrangeRd = Color(0xFFF0480C);
  static const Color ribbonOrange   = Color(0xFFF06000);
  static const Color ribbonAmber    = Color(0xFFF0C000);
  static const Color ribbonYellow   = Color(0xFFF0E060);
  static const Color ribbonCream    = Color(0xFFFFF6CC);

  /// Brand primary — the signature pink. Held constant in both
  /// modes since it's the most recognizable Vistar accent and reads
  /// well against both near-black and paper-white.
  static const Color primary       = ribbonPink;
  static const Color primaryDark   = Color(0xFFB81570);
  static const Color primaryLight  = Color(0xFFEA4CA1);
  static const Color accent        = ribbonOrange;
  static const Color purple        = ribbonViolet;

  // Hard whites and blacks for places where we genuinely want
  // "white text on a colored fill" or "true black" (the deep page
  // is bgDeep, not this).
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Ribbon gradient stops + positions (used by `ribbonGradient()`).
  static const List<Color> ribbonStops = [
    Color(0xFF7A1FB0),
    Color(0xFFB81FB8),
    Color(0xFFE0218A),
    Color(0xFFD11630),
    Color(0xFFF0480C),
    Color(0xFFF06000),
    Color(0xFFF0C000),
    Color(0xFFF7EE9A),
  ];
  static const List<double> ribbonStopsAt = [
    0.0, 0.22, 0.40, 0.56, 0.70, 0.80, 0.92, 1.0,
  ];

  // ════════════════════════════════════════════════════════════════
  // MODE-AWARE TOKENS (runtime getters — never use in const ctors)
  // ════════════════════════════════════════════════════════════════

  // ── Surfaces ────────────────────────────────────────────────────
  static Color get bgDeep => _isDark
      ? const Color(0xFF070611)
      : const Color(0xFFF6F4FB);
  static Color get bgRaised => _isDark
      ? const Color(0xFF0B0A18)
      : const Color(0xFFFFFFFF);
  static Color get surface => _isDark
      ? const Color(0xFF110F1E)
      : const Color(0xFFFFFFFF);
  static Color get surface2 => _isDark
      ? const Color(0xFF16142A)
      : const Color(0xFFF3F0FA);
  static Color get surface3 => _isDark
      ? const Color(0xFF1D1A33)
      : const Color(0xFFE8E2F4);

  // Legacy aliases. These map onto the surface scale so existing
  // call-sites adopt the right mode automatically.
  static Color get background => bgDeep;
  static Color get cardBackground => surface;

  // ── Hairlines & dividers ────────────────────────────────────────
  static Color get line => _isDark
      ? const Color(0x14FFFFFF)  // white 8%
      : const Color(0x14000000); // black 8%
  static Color get line2 => _isDark
      ? const Color(0x21FFFFFF)  // white 13%
      : const Color(0x22000000); // black 13%
  static Color get border => line;
  static Color get divider => line;

  // ── Text scale ──────────────────────────────────────────────────
  static Color get textPrimary => _isDark
      ? const Color(0xFFF2EEFB)
      : const Color(0xFF0B0A18);
  static Color get textSecondary => _isDark
      ? const Color(0xFFB9B2D6)
      : const Color(0xFF4A4666);
  static Color get textMuted => _isDark
      ? const Color(0xFF7E769B)
      : const Color(0xFF7E769B);

  // Inactive / overlay scrim.
  static Color get inactive => surface2;
  static Color get overlay => _isDark
      ? const Color(0xCC050410)
      : const Color(0x99000814);

  // ── Semantic status colors ──────────────────────────────────────
  // Dark mode uses lighter, glowier hues to read against near-black;
  // light mode uses deeper, more saturated hues for contrast on white.
  static Color get success => _isDark
      ? const Color(0xFF34D399)
      : const Color(0xFF15803D);
  static Color get secondary => success; // legacy alias
  static Color get warning => _isDark
      ? const Color(0xFFFBBF24)
      : const Color(0xFFB45309);
  static Color get danger => _isDark
      ? const Color(0xFFFB6F84)
      : const Color(0xFFDC2626);
  static Color get info => _isDark
      ? const Color(0xFF5BA8FF)
      : const Color(0xFF2563EB);

  // ── Tints (translucent so they always read on the active canvas) ─
  // The same brand-tinted families are used in both modes; opacities
  // are tuned per-mode so the pill background reads but doesn't
  // overpower the canvas.
  static Color get greenTint => _isDark
      ? const Color(0x2434D399)
      : const Color(0x2415803D);
  static Color get amberTint => _isDark
      ? const Color(0x24FBBF24)
      : const Color(0x24B45309);
  static Color get redTint => _isDark
      ? const Color(0x24FB6F84)
      : const Color(0x24DC2626);
  static Color get blueTint => _isDark
      ? const Color(0x245BA8FF)
      : const Color(0x242563EB);
  static Color get greyTint => _isDark
      ? const Color(0x12FFFFFF)
      : const Color(0x0F000000);

  // Audit result backgrounds.
  static Color get passBackground => greenTint;
  static Color get failBackground => redTint;
  static Color get naBackground => _isDark
      ? const Color(0x14FFFFFF)
      : const Color(0x0F000000);

  // Audit result borders.
  static Color get passBorder => success;
  static Color get failBorder => danger;
  static Color get naBorder => _isDark
      ? const Color(0x33FFFFFF)
      : const Color(0x22000000);
}

/// The signature Vistar ribbon gradient — a 115° rainbow sweep that
/// echoes the S-mark. Use sparingly: primary CTAs, active-nav rails,
/// KPI numbers (via [ShaderMask]), the "on" role chip.
LinearGradient ribbonGradient({
  AlignmentGeometry begin = const Alignment(-1, -0.4),
  AlignmentGeometry end   = const Alignment(1, 0.4),
}) =>
    LinearGradient(
      begin: begin,
      end: end,
      colors: AppColors.ribbonStops,
      stops: AppColors.ribbonStopsAt,
    );

/// Softer translucent variant of [ribbonGradient]; useful as a faint
/// halo behind dark surfaces.
LinearGradient ribbonGradientSoft({
  AlignmentGeometry begin = const Alignment(-1, -0.4),
  AlignmentGeometry end   = const Alignment(1, 0.4),
  double opacity = 0.85,
}) =>
    LinearGradient(
      begin: begin,
      end: end,
      colors: [
        const Color(0xFF9B30C9).withValues(alpha: opacity),
        const Color(0xFFE0218A).withValues(alpha: opacity),
        const Color(0xFFF0480C).withValues(alpha: opacity),
        const Color(0xFFF0C000).withValues(alpha: opacity),
      ],
    );
