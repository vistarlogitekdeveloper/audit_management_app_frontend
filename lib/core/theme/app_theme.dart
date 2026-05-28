import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Vistar Premium theme — supports both **light** and **dark** modes.
/// Both themes share the same Bricolage/Manrope typography, the same
/// ribbon-pink primary, and the same component grammar (rounded
/// corners, ribbon focus rings, ribbon-gradient buttons via
/// [AppButton]). Only the surface scale, hairline colors, and
/// semantic statuses flip per mode.
///
/// Most properties read from the mode-aware getters on [AppColors],
/// so building either theme is simply a matter of toggling
/// [appBrightness] beforehand. The two factories below do exactly
/// that, then restore the prior value so callers can request either
/// theme regardless of the live mode (e.g. `MaterialApp(theme:..., darkTheme:...)`
/// calls both at startup).
class AppTheme {
  /// Backwards-compatibility alias — historically the app only had a
  /// "lightTheme" handle. It now resolves to the active dark theme
  /// when no themeMode is plumbed through MaterialApp.
  static ThemeData get lightTheme => light;

  /// Returns the dark variant of the Vistar Premium theme.
  static ThemeData get dark => _buildFor(Brightness.dark);

  /// Returns the light variant of the Vistar Premium theme.
  static ThemeData get light => _buildFor(Brightness.light);

  static ThemeData _buildFor(Brightness brightness) {
    // Temporarily set the global so AppColors getters resolve to the
    // requested mode while we build the ThemeData. Restored at the
    // end so the live UI doesn't visually flicker on theme rebuild.
    final previous = appBrightness.value;
    appBrightness.value = brightness;
    try {
      return _construct(brightness);
    } finally {
      appBrightness.value = previous;
    }
  }

  static ThemeData _construct(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = ThemeData(useMaterial3: true, brightness: brightness);

    return base.copyWith(
      brightness: brightness,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.primary,
        onPrimary: AppColors.white,
        secondary: AppColors.success,
        onSecondary: isDark ? AppColors.bgDeep : AppColors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.surface2,
        error: AppColors.danger,
        onError: AppColors.white,
        outline: AppColors.line,
        outlineVariant: AppColors.line2,
      ),
      scaffoldBackgroundColor: AppColors.bgDeep,
      canvasColor: AppColors.bgDeep,

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.primary.withValues(alpha: 0.32),
        selectionHandleColor: AppColors.primary,
      ),

      textTheme: TextTheme(
        headlineSmall: AppTextStyles.headline22,
        titleLarge: AppTextStyles.title18,
        titleMedium: AppTextStyles.title16,
        bodyLarge: AppTextStyles.body16,
        bodyMedium: AppTextStyles.body14,
        bodySmall: AppTextStyles.body12,
        labelLarge: AppTextStyles.medium14,
        labelMedium: AppTextStyles.medium12,
        labelSmall: AppTextStyles.body11,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgDeep,
        foregroundColor: AppColors.textPrimary,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: GoogleFonts.bricolageGrotesque(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
        ),
      ),

      iconTheme: IconThemeData(color: AppColors.textPrimary),
      cardColor: AppColors.surface,

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.primary.withValues(alpha: 0.32);
            }
            if (states.contains(WidgetState.pressed)) {
              return AppColors.primaryDark;
            }
            return AppColors.primary;
          }),
          foregroundColor: const WidgetStatePropertyAll(AppColors.white),
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(46)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
          ),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          elevation: const WidgetStatePropertyAll(0),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return AppColors.white.withValues(alpha: 0.10);
            }
            return null;
          }),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(46),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
          textStyle: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size.fromHeight(46),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
          side: BorderSide(color: AppColors.line2),
          textStyle: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700),
          backgroundColor: AppColors.surface2,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.line),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        isDense: false,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.6),
            width: 1.6,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: AppColors.danger, width: 1.6),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: AppColors.line),
        ),
        labelStyle: GoogleFonts.manrope(
          fontSize: 13,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: GoogleFonts.manrope(
          fontSize: 13,
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: GoogleFonts.manrope(
          fontSize: 13,
          color: AppColors.textMuted,
          fontWeight: FontWeight.w400,
        ),
        helperStyle: GoogleFonts.manrope(
          fontSize: 11,
          color: AppColors.textMuted,
          fontWeight: FontWeight.w500,
        ),
        errorStyle: GoogleFonts.manrope(
          fontSize: 11,
          color: AppColors.danger,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textMuted,
      ),

      dividerTheme: DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 0,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surface2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(11),
          side: BorderSide(color: AppColors.line2),
        ),
        contentTextStyle: GoogleFonts.manrope(
          fontSize: 13,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: AppColors.primary,
        elevation: 0,
      ),

      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.line),
        ),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.bricolageGrotesque(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
        ),
        contentTextStyle: GoogleFonts.manrope(
          fontSize: 14,
          color: AppColors.textSecondary,
          height: 1.45,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          side: BorderSide(color: AppColors.line),
        ),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.surface3,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.line2),
        ),
        textStyle: GoogleFonts.manrope(
          fontSize: 12,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        waitDuration: const Duration(milliseconds: 400),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface2,
        selectedColor: AppColors.primary.withValues(alpha: 0.16),
        side: BorderSide(color: AppColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        labelStyle: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        secondaryLabelStyle: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        },
      ),

      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return AppColors.primary.withValues(alpha: 0.6);
          }
          return AppColors.ribbonViolet.withValues(alpha: 0.45);
        }),
        thickness: const WidgetStatePropertyAll(8),
        radius: const Radius.circular(8),
        crossAxisMargin: 2,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.line,
        circularTrackColor: AppColors.line,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.white
                : AppColors.textMuted),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.surface2),
        trackOutlineColor: WidgetStatePropertyAll(AppColors.line),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.primary
                : Colors.transparent),
        checkColor: const WidgetStatePropertyAll(AppColors.white),
        side: BorderSide(color: AppColors.line2, width: 1.4),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textMuted),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface2,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(11),
          side: BorderSide(color: AppColors.line),
        ),
        textStyle: GoogleFonts.manrope(
          fontSize: 13,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.18),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 66,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.primary : AppColors.textMuted,
            letterSpacing: 0.2,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: selected ? AppColors.primary : AppColors.textMuted,
          );
        }),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
        subtitleTextStyle: AppTextStyles.body12,
        titleTextStyle: AppTextStyles.medium14,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),

      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: AppTextStyles.body14,
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(AppColors.surface2),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
            side: BorderSide(color: AppColors.line),
          )),
        ),
      ),

      badgeTheme: const BadgeThemeData(
        backgroundColor: AppColors.primary,
        textColor: AppColors.white,
      ),
    );
  }
}
