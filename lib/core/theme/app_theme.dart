import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final base = ThemeData(useMaterial3: true);

    return base.copyWith(
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.cardBackground,
        surfaceContainerHighest: AppColors.greyTint,
        error: AppColors.danger,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: AppColors.textPrimary,
        onError: AppColors.white,
        outline: AppColors.border,
      ),
      scaffoldBackgroundColor: AppColors.background,

      // ── Typography ────────────────────────────────────────────────────
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

      // ── App bar (still flat, but cleaner spacing) ─────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.cardBackground,
        foregroundColor: AppColors.textPrimary,
        centerTitle: false,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),

      cardColor: AppColors.cardBackground,

      // ── Buttons (taller default, smoother corners, subtle pressed state) ─
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.primary.withValues(alpha: 0.4);
            }
            if (states.contains(WidgetState.pressed)) {
              return AppColors.primaryDark;
            }
            return AppColors.primary;
          }),
          foregroundColor: const WidgetStatePropertyAll(AppColors.white),
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(46)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          elevation: const WidgetStatePropertyAll(0),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return AppColors.white.withValues(alpha: 0.08);
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(46),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          backgroundColor: AppColors.white,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),

      // ── Cards ─────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Inputs (animated label, larger tap target, helper-text aware) ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        isDense: false,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.6),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w400,
        ),
        floatingLabelStyle: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.textMuted,
          fontWeight: FontWeight.w400,
        ),
        helperStyle: GoogleFonts.inter(
          fontSize: 11,
          color: AppColors.textMuted,
          fontWeight: FontWeight.w400,
        ),
        errorStyle: GoogleFonts.inter(
          fontSize: 11,
          color: AppColors.danger,
          fontWeight: FontWeight.w500,
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 0,
      ),

      // ── Snackbar (branded, rounded, dismiss action) ────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.white,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: AppColors.white,
        elevation: 6,
      ),

      // ── Dialog ────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: AppColors.cardBackground,
        elevation: 8,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),

      // ── Bottom sheet ──────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.cardBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),

      // ── Tooltip ───────────────────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.textPrimary.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.white),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        waitDuration: const Duration(milliseconds: 400),
      ),

      // ── Chip + ChoiceChip ─────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.greyTint,
        selectedColor: AppColors.primary.withValues(alpha: 0.10),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),

      // ── Page transitions: fade-through everywhere ─────────────────────
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        },
      ),

      // ── Scrollbar — visible on web/desktop, slimmer on mobile ─────────
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return AppColors.primary.withValues(alpha: 0.5);
          }
          return AppColors.textMuted.withValues(alpha: 0.5);
        }),
        thickness: const WidgetStatePropertyAll(8),
        radius: const Radius.circular(8),
        crossAxisMargin: 2,
      ),
    );
  }
}
