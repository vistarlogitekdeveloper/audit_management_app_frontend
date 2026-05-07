import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum AppButtonVariant { primary, ghost, danger, success }

enum AppButtonSize { regular, small, large }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = false,
    this.size = AppButtonSize.regular,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final AppButtonSize size;

  @override
  Widget build(BuildContext context) {
    final disabled = isLoading || onPressed == null;
    final palette = _palette(variant);
    final dims = _dimensions(size);

    final child = AnimatedSwitcher(
      duration: const Duration(milliseconds: 140),
      transitionBuilder: (c, a) =>
          FadeTransition(opacity: a, child: ScaleTransition(scale: a, child: c)),
      child: isLoading
          ? Row(
              key: const ValueKey('loading'),
              mainAxisSize:
                  isFullWidth ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: dims.iconSize,
                  height: dims.iconSize,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(palette.fg),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Working…',
                  style: dims.labelStyle.copyWith(color: palette.fg),
                ),
              ],
            )
          : Row(
              key: const ValueKey('idle'),
              mainAxisSize:
                  isFullWidth ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: dims.iconSize, color: palette.fg),
                  const SizedBox(width: 8),
                ],
                Text(label,
                    style: dims.labelStyle.copyWith(color: palette.fg)),
              ],
            ),
    );

    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));
    final minSize = Size(isFullWidth ? double.infinity : 0, dims.minHeight);

    final Widget button = variant == AppButtonVariant.ghost
        ? OutlinedButton(
            onPressed: disabled ? null : onPressed,
            style: OutlinedButton.styleFrom(
              backgroundColor: palette.bg,
              foregroundColor: palette.fg,
              minimumSize: minSize,
              shape: shape,
              side: BorderSide(color: palette.border ?? AppColors.border),
              padding: dims.padding,
            ),
            child: child,
          )
        : FilledButton(
            onPressed: disabled ? null : onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: palette.bg,
              foregroundColor: palette.fg,
              minimumSize: minSize,
              shape: shape,
              padding: dims.padding,
              elevation: 0,
            ),
            child: child,
          );

    return isFullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }

  static _Palette _palette(AppButtonVariant v) {
    switch (v) {
      case AppButtonVariant.primary:
        return const _Palette(
            bg: AppColors.primary, fg: AppColors.white);
      case AppButtonVariant.ghost:
        return const _Palette(
            bg: AppColors.white,
            fg: AppColors.primary,
            border: AppColors.border);
      case AppButtonVariant.danger:
        return const _Palette(bg: AppColors.danger, fg: AppColors.white);
      case AppButtonVariant.success:
        return const _Palette(bg: AppColors.success, fg: AppColors.white);
    }
  }

  static _Dims _dimensions(AppButtonSize s) {
    switch (s) {
      case AppButtonSize.small:
        return _Dims(
          minHeight: 36,
          iconSize: 16,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          labelStyle: AppTextStyles.medium13,
        );
      case AppButtonSize.large:
        return _Dims(
          minHeight: 52,
          iconSize: 20,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          labelStyle: AppTextStyles.medium14.copyWith(fontSize: 15),
        );
      case AppButtonSize.regular:
        return _Dims(
          minHeight: 46,
          iconSize: 18,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          labelStyle: AppTextStyles.medium14,
        );
    }
  }
}

class _Palette {
  const _Palette({required this.bg, required this.fg, this.border});
  final Color bg;
  final Color fg;
  final Color? border;
}

class _Dims {
  const _Dims({
    required this.minHeight,
    required this.iconSize,
    required this.padding,
    required this.labelStyle,
  });
  final double minHeight;
  final double iconSize;
  final EdgeInsetsGeometry padding;
  final TextStyle labelStyle;
}
