import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Vistar Premium typography.
///
/// • Display (h1–h4, page titles, KPI numbers, brand) → Bricolage Grotesque
///   with a subtle negative letter-spacing for an editorial feel.
/// • Body (paragraphs, labels, tables, inputs) → Manrope, antialiased
///   with a hair of positive letter-spacing for legibility on dark.
class AppTextStyles {
  // ── Display (Bricolage Grotesque) ───────────────────────────────
  static TextStyle get headline22 => GoogleFonts.bricolageGrotesque(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.4,
        height: 1.2,
      );

  static TextStyle get title18 => GoogleFonts.bricolageGrotesque(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
        height: 1.25,
      );

  static TextStyle get title16 => GoogleFonts.bricolageGrotesque(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
        height: 1.3,
      );

  /// KPI value style — Bricolage extra bold, slightly larger so it
  /// reads as a hero number against the body text.
  static TextStyle get statValue => GoogleFonts.bricolageGrotesque(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
        height: 1.0,
      );

  // ── Body (Manrope) ──────────────────────────────────────────────
  static TextStyle get body16 => GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        letterSpacing: 0.1,
        height: 1.5,
      );

  static TextStyle get body14 => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        letterSpacing: 0.1,
        height: 1.45,
      );

  static TextStyle get medium14 => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.1,
        height: 1.4,
      );

  static TextStyle get body13 => GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        letterSpacing: 0.1,
        height: 1.45,
      );

  static TextStyle get medium13 => GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.1,
        height: 1.4,
      );

  static TextStyle get body12 => GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        letterSpacing: 0.1,
        height: 1.45,
      );

  static TextStyle get medium12 => GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.2,
        height: 1.4,
      );

  static TextStyle get body11 => GoogleFonts.manrope(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
        letterSpacing: 0.2,
        height: 1.4,
      );

  static TextStyle get body10 => GoogleFonts.manrope(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
        letterSpacing: 0.3,
        height: 1.4,
      );

  /// Uppercase eyebrow style — group labels, section captions.
  static TextStyle get eyebrow => GoogleFonts.manrope(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 1.4,
        height: 1.3,
      );
}
