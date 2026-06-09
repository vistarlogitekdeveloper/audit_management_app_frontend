import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/status_pill.dart';

class AuditRowWidget extends StatefulWidget {
  const AuditRowWidget({
    super.key,
    required this.index,
    required this.parameterName,
    required this.selectedResult,
    required this.onResultChanged,
    required this.remarkController,
    required this.onRemarkChanged,
    this.showValidation = false,
    this.isReadOnly = false,
  });

  final int index;
  final String parameterName;
  final String? selectedResult;
  final ValueChanged<String> onResultChanged;
  final TextEditingController remarkController;
  final ValueChanged<String> onRemarkChanged;
  final bool showValidation;
  final bool isReadOnly;

  @override
  State<AuditRowWidget> createState() => _AuditRowWidgetState();
}

class _AuditRowWidgetState extends State<AuditRowWidget> {
  bool get _answered => widget.selectedResult != null;

  bool get _remarkMissing => widget.remarkController.text.trim().isEmpty;

  @override
  Widget build(BuildContext context) {
    final invalid = !widget.isReadOnly &&
        widget.showValidation &&
        (!_answered || _remarkMissing);

    // A subtle left accent tinted by the chosen result gives each card a
    // quick-scan status without leaning on extra chrome.
    final accent = switch (widget.selectedResult) {
      AppConstants.resultPass => AppColors.passBorder,
      AppConstants.resultFail => AppColors.failBorder,
      AppConstants.resultNA => AppColors.naBorder,
      _ => AppColors.border,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        // Mode-aware surface so the card (and its text) stays legible in dark
        // mode — a hardcoded white card hid the light-on-light text.
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: invalid ? AppColors.danger : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header strip: numbered badge + parameter name, with a coloured
          // left edge that reflects the current result.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 14, 14, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _IndexBadge(index: widget.index, answered: _answered),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              widget.parameterName,
                              style: AppTextStyles.medium14.copyWith(
                                height: 1.35,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PFNToggle(
                  selected: widget.selectedResult,
                  onSelected: widget.onResultChanged,
                  isReadOnly: widget.isReadOnly,
                ),
                const SizedBox(height: 14),
                const _FieldLabel(
                  icon: Icons.notes_rounded,
                  label: 'Remark',
                  required: true,
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: widget.remarkController,
                  maxLines: 2,
                  enabled: !widget.isReadOnly,
                  onChanged: (value) {
                    widget.onRemarkChanged(value);
                    // Rebuild so the inline error clears as soon as the auditor
                    // starts typing a remark.
                    if (widget.showValidation) setState(() {});
                  },
                  style: AppTextStyles.body13.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: widget.isReadOnly
                        ? AppColors.greyTint
                        : AppColors.background,
                    hintText: 'Describe the observation…',
                    hintStyle: AppTextStyles.body12,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.4,
                      ),
                    ),
                    errorText: invalid && _remarkMissing
                        ? 'Remark is required'
                        : null,
                  ),
                ),
                if (widget.selectedResult != null) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: StatusPill(status: widget.selectedResult!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small numbered badge in front of each parameter. Turns into a check once the
/// row has a result so the auditor can see at a glance what's done.
class _IndexBadge extends StatelessWidget {
  const _IndexBadge({required this.index, required this.answered});

  final int index;
  final bool answered;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: answered
            ? AppColors.secondary.withValues(alpha: 0.12)
            : AppColors.blueTint,
        borderRadius: BorderRadius.circular(8),
      ),
      child: answered
          ? Icon(Icons.check_rounded,
              size: 16, color: AppColors.secondary)
          : Text(
              '$index',
              style: AppTextStyles.medium12.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.icon,
    required this.label,
    this.required = false,
  });

  final IconData icon;
  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTextStyles.medium12.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 3),
          Text(
            '*',
            style: AppTextStyles.medium12.copyWith(color: AppColors.danger),
          ),
        ],
      ],
    );
  }
}

class PFNToggle extends StatelessWidget {
  const PFNToggle({
    super.key,
    required this.selected,
    required this.onSelected,
    this.isReadOnly = false,
  });

  final String? selected;
  final ValueChanged<String> onSelected;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ResultChip(
          label: 'Pass',
          icon: Icons.check_circle_outline_rounded,
          value: AppConstants.resultPass,
          selected: selected,
          onSelected: onSelected,
          selectedColor: AppColors.passBackground,
          borderColor: AppColors.passBorder,
          textColor: AppColors.secondary,
          isReadOnly: isReadOnly,
        ),
        const SizedBox(width: 8),
        _ResultChip(
          label: 'Fail',
          icon: Icons.cancel_outlined,
          value: AppConstants.resultFail,
          selected: selected,
          onSelected: onSelected,
          selectedColor: AppColors.failBackground,
          borderColor: AppColors.failBorder,
          textColor: AppColors.danger,
          isReadOnly: isReadOnly,
        ),
        const SizedBox(width: 8),
        _ResultChip(
          label: 'NA',
          icon: Icons.remove_circle_outline_rounded,
          value: AppConstants.resultNA,
          selected: selected,
          onSelected: onSelected,
          selectedColor: AppColors.naBackground,
          borderColor: AppColors.naBorder,
          textColor: AppColors.textSecondary,
          isReadOnly: isReadOnly,
        ),
      ],
    );
  }
}

class _ResultChip extends StatelessWidget {
  const _ResultChip({
    required this.label,
    required this.icon,
    required this.value,
    required this.selected,
    required this.onSelected,
    required this.selectedColor,
    required this.borderColor,
    required this.textColor,
    this.isReadOnly = false,
  });

  final String label;
  final IconData icon;
  final String value;
  final String? selected;
  final ValueChanged<String> onSelected;
  final Color selectedColor;
  final Color borderColor;
  final Color textColor;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context) {
    final active = selected == value;
    return Expanded(
      child: InkWell(
        onTap: isReadOnly ? null : () => onSelected(value),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? selectedColor : AppColors.surface2,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active ? borderColor : AppColors.border,
              width: active ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: active ? textColor : AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.medium12.copyWith(
                    color: active ? textColor : AppColors.textSecondary,
                    fontWeight: active ? FontWeight.w500 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
