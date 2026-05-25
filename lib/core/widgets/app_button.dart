import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum AppButtonVariant { primary, ghost, danger, success }

enum AppButtonSize { regular, small, large }

/// Branded button. The primary variant uses the signature ribbon
/// gradient (painted via [DecoratedBox] since Material's stock
/// ButtonStyle cannot host a gradient), with a soft pink halo. Ghost
/// is the dark outlined variant; danger / success use flat semantic
/// colors so warning actions stay legible.
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
    final dims = _dimensions(size);

    final content = AnimatedSwitcher(
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
                    valueColor:
                        AlwaysStoppedAnimation<Color>(_foreground(variant)),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Working…',
                  style: dims.labelStyle.copyWith(color: _foreground(variant)),
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
                  Icon(icon, size: dims.iconSize, color: _foreground(variant)),
                  const SizedBox(width: 8),
                ],
                Text(label,
                    style: dims.labelStyle.copyWith(color: _foreground(variant))),
              ],
            ),
    );

    final Widget body;
    if (variant == AppButtonVariant.primary) {
      body = _RibbonButton(
        onPressed: disabled ? null : onPressed,
        height: dims.minHeight,
        padding: dims.padding,
        isFullWidth: isFullWidth,
        child: content,
      );
    } else {
      final palette = _palette(variant);
      final shape =
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(11));
      final minSize = Size(isFullWidth ? double.infinity : 0, dims.minHeight);

      body = variant == AppButtonVariant.ghost
          ? OutlinedButton(
              onPressed: disabled ? null : onPressed,
              style: OutlinedButton.styleFrom(
                backgroundColor: palette.bg,
                foregroundColor: palette.fg,
                minimumSize: minSize,
                shape: shape,
                side: BorderSide(color: palette.border ?? AppColors.line2),
                padding: dims.padding,
              ),
              child: content,
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
              child: content,
            );
    }

    return isFullWidth
        ? SizedBox(width: double.infinity, child: body)
        : body;
  }

  static Color _foreground(AppButtonVariant v) {
    switch (v) {
      case AppButtonVariant.primary:
        return AppColors.white;
      case AppButtonVariant.ghost:
        return AppColors.textPrimary;
      case AppButtonVariant.danger:
        return AppColors.white;
      case AppButtonVariant.success:
        return AppColors.bgDeep;
    }
  }

  static _Palette _palette(AppButtonVariant v) {
    switch (v) {
      case AppButtonVariant.primary:
        return const _Palette(bg: AppColors.primary, fg: AppColors.white);
      case AppButtonVariant.ghost:
        return _Palette(
            bg: AppColors.surface2,
            fg: AppColors.textPrimary,
            border: AppColors.line2);
      case AppButtonVariant.danger:
        return _Palette(bg: AppColors.danger, fg: AppColors.white);
      case AppButtonVariant.success:
        return _Palette(bg: AppColors.success, fg: AppColors.bgDeep);
    }
  }

  static _Dims _dimensions(AppButtonSize s) {
    switch (s) {
      case AppButtonSize.small:
        return _Dims(
          minHeight: 38,
          iconSize: 16,
          padding: const EdgeInsets.symmetric(horizontal: 14),
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

class _RibbonButton extends StatelessWidget {
  const _RibbonButton({
    required this.onPressed,
    required this.height,
    required this.padding,
    required this.isFullWidth,
    required this.child,
  });

  final VoidCallback? onPressed;
  final double height;
  final EdgeInsetsGeometry padding;
  final bool isFullWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return Opacity(
      opacity: disabled ? 0.55 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            gradient: ribbonGradient(),
            boxShadow: disabled
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.45),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(11),
            splashColor: AppColors.white.withValues(alpha: 0.10),
            highlightColor: AppColors.white.withValues(alpha: 0.06),
            child: Container(
              constraints: BoxConstraints(
                minHeight: height,
                minWidth: isFullWidth ? double.infinity : 0,
              ),
              padding: padding,
              alignment: Alignment.center,
              child: child,
            ),
          ),
        ),
      ),
    );
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
