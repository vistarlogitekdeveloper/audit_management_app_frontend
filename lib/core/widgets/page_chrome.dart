import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'brand.dart';

/// Hero header used at the top of most screens.
///
/// Renders as a near-black surface with a faint ribbon underglow and
/// a tinted icon tile. Mobile (< 700px) collapses the action below the
/// title block so the button never gets cut off on small screens.
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
  Widget build(BuildContext context) => AnimatedBuilder(
        // Re-resolve mode-aware colours when the theme toggles, even if this
        // widget's element is reused (and so wouldn't otherwise rebuild).
        animation: appBrightness,
        builder: (context, _) => _build(context),
      );

  Widget _build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 700;
    final pad = compact ? 18.0 : 24.0;

    final left = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroIcon(icon: icon, tone: tone),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.headline22.copyWith(
                  fontSize: compact ? 22 : 26,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: AppTextStyles.body14.copyWith(
                  color: AppColors.textSecondary,
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface2, AppColors.surface],
        ),
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: tone.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Faint S accent in the corner.
          const Positioned(
            right: -28,
            bottom: -34,
            child: Opacity(
              opacity: 0.07,
              child: SizedBox(
                width: 160,
                height: 160,
                child: Image(image: AssetImage(kSMarkAsset)),
              ),
            ),
          ),
          compact
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
        ],
      ),
    );
  }
}

class _HeroIcon extends StatelessWidget {
  const _HeroIcon({required this.icon, required this.tone});
  final IconData icon;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tone.withValues(alpha: 0.36)),
      ),
      child: Icon(icon, color: tone, size: 22),
    );
  }
}

/// Section card used on every screen. Subtle ribbon underglow, dark
/// surface, 1px hairline border, responsive padding so panels feel
/// modern instead of flat boxes.
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

  /// Optional trailing widget to the right of the title row (e.g. a
  /// "View all" link or filter button).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: appBrightness,
        builder: (context, _) => _build(context),
      );

  Widget _build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final defaultPad = dense
        ? const EdgeInsets.all(14)
        : EdgeInsets.all(width < 600 ? 16 : 20);

    return Container(
      width: double.infinity,
      padding: padding ?? defaultPad,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                const RibbonAccent(),
                const SizedBox(width: 10),
                if (icon != null) ...[
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.28)),
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
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: appBrightness,
        builder: (context, _) => _build(context),
      );

  Widget _build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.30)),
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

/// Friendly empty-state used when a list/section has no data.
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
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: appBrightness,
        builder: (context, _) => _build(context),
      );

  Widget _build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.30)),
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
