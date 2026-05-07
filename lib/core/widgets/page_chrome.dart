import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Hero header used at the top of most screens.
///
/// Mobile (< 700px) collapses the action below the title block instead of
/// trying to wrap them on the same row, which previously made the action
/// button overlap or get cut off on small screens.
class PageHero extends StatelessWidget {
  const PageHero({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.action,
    this.tone = AppColors.primary,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? action;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 700;
    final pad = compact ? 18.0 : 24.0;

    final left = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroIcon(icon: icon),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.headline22.copyWith(
                  color: AppColors.white,
                  fontSize: compact ? 22 : 26,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: AppTextStyles.body14.copyWith(
                  color: AppColors.white.withValues(alpha: 0.86),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tone, _darker(tone)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: tone.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                left,
                if (action != null) ...[
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IntrinsicWidth(child: action!),
                  ),
                ],
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: left),
                if (action != null) ...[
                  const SizedBox(width: 16),
                  IntrinsicWidth(child: action!),
                ],
              ],
            ),
    );
  }

  static Color _darker(Color base) {
    final hsl = HSLColor.fromColor(base);
    return hsl
        .withLightness((hsl.lightness * 0.78).clamp(0.0, 1.0))
        .toColor();
  }
}

class _HeroIcon extends StatelessWidget {
  const _HeroIcon({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.22)),
      ),
      child: Icon(icon, color: AppColors.white, size: 22),
    );
  }
}

/// Section card used on every screen. Subtle shadow + rounded corners +
/// responsive padding so panels feel modern instead of flat boxes.
class AppPanel extends StatelessWidget {
  const AppPanel({
    super.key,
    required this.child,
    this.title,
    this.icon,
    this.padding,
    this.dense = false,
    this.trailing,
  });

  final Widget child;
  final String? title;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;
  final bool dense;

  /// Optional trailing widget to the right of the title row (e.g. a "View
  /// all" link or filter button).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final defaultPad = dense
        ? const EdgeInsets.all(12)
        : EdgeInsets.all(width < 600 ? 14 : 18);

    return Container(
      width: double.infinity,
      padding: padding ?? defaultPad,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 16, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(child: Text(title!, style: AppTextStyles.title16)),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }
}

/// Compact metric tile used inside [AppPanel] grids.
class InfoMetric extends StatelessWidget {
  const InfoMetric({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.greyTint,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.body11),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.medium14.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Friendly empty-state used when a list/section has no data. The icon
/// floats inside a tinted square to feel less like a 404.
class EmptyPanel extends StatelessWidget {
  const EmptyPanel({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.greyTint,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 26),
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: AppTextStyles.body13),
          if (action != null) ...[
            const SizedBox(height: 12),
            action!,
          ],
        ],
      ),
    );
  }
}
