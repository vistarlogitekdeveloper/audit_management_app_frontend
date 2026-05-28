import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Polished text input on the Vistar dark surface. Animated focus
/// halo in ribbon pink, a small label that adopts the focus color,
/// dim placeholder, and an optional show/hide toggle for password
/// fields. Read-only inputs get a slightly lifted fill so they read
/// as "chip" cells.
class AppInput extends StatefulWidget {
  const AppInput({
    super.key,
    required this.label,
    this.hint,
    this.helper,
    this.controller,
    this.validator,
    this.isReadOnly = false,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.onTap,
    this.onChanged,
    this.autofocus = false,
    this.enabled = true,
    this.dense = false,
  });

  final String label;
  final String? hint;
  final String? helper;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool isReadOnly;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;
  final int? maxLength;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final bool enabled;
  final bool dense;

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  late final FocusNode _focusNode;
  bool _focused = false;
  bool _obscured = true;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    _obscured = widget.obscureText;
  }

  void _onFocusChange() {
    if (mounted) setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasObscureToggle = widget.obscureText;
    final fill = !widget.enabled
        ? AppColors.surface2
        : (widget.isReadOnly ? AppColors.surface2 : AppColors.surface);

    final field = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        boxShadow: _focused && widget.enabled
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  blurRadius: 0,
                  spreadRadius: 4,
                ),
              ]
            : const [],
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        validator: widget.validator,
        readOnly: widget.isReadOnly,
        enabled: widget.enabled,
        obscureText: hasObscureToggle ? _obscured : false,
        keyboardType: widget.keyboardType,
        maxLines: widget.obscureText ? 1 : widget.maxLines,
        maxLength: widget.maxLength,
        onTap: widget.onTap,
        onChanged: widget.onChanged,
        autofocus: widget.autofocus,
        style: AppTextStyles.body14,
        cursorColor: AppColors.primary,
        decoration: InputDecoration(
          fillColor: fill,
          isDense: widget.dense,
          contentPadding: widget.dense
              ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
              : null,
          hintText: widget.hint,
          helperText: widget.helper,
          prefixIcon: widget.prefixIcon == null
              ? null
              : Icon(widget.prefixIcon,
                  size: 18, color: AppColors.textMuted),
          suffixIcon: hasObscureToggle
              ? IconButton(
                  onPressed: () => setState(() => _obscured = !_obscured),
                  icon: Icon(
                    _obscured
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 19,
                    color: AppColors.textMuted,
                  ),
                  tooltip: _obscured ? 'Show password' : 'Hide password',
                )
              : widget.suffixIcon,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTextStyles.medium13.copyWith(
            color: _focused ? AppColors.primary : AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 7),
        field,
      ],
    );
  }
}
