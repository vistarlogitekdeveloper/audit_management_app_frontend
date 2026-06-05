import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/page_chrome.dart';
import '../../../core/widgets/status_pill.dart';
import '../models/action_plan_model.dart';

/// Who is looking at this card, which controls which inputs / buttons render:
/// - [edit]    : owner fills in corrective action, person, due date, status.
/// - [review]  : auditor reads only; can Approve / Reject with a remark.
/// - [readOnly]: cluster manager / anyone else; everything disabled.
enum ActionItemMode { edit, review, readOnly }

class ActionItemWidget extends StatefulWidget {
  const ActionItemWidget({
    super.key,
    required this.item,
    required this.onChanged,
    required this.deadline,
    this.hasValidationError = false,
    this.mode = ActionItemMode.edit,
    this.onReview,
    this.reviewing = false,
    this.auditObservation,
    this.responsiblePersonSuggestions = const [],
  });

  final ActionItemModel item;
  final ValueChanged<ActionItemModel> onChanged;

  /// Latest acceptable due date (audit_date + 8 days) for any item.
  final DateTime deadline;

  /// When true, missing/invalid fields are highlighted in red.
  final bool hasValidationError;

  /// Controls which inputs / buttons render (see [ActionItemMode]).
  final ActionItemMode mode;

  /// Invoked by the Approve / Reject buttons when [mode] is review.
  /// Signature: (reviewStatus, remark) — remark is required for 'rejected'.
  final Future<void> Function(String reviewStatus, String remark)? onReview;

  /// When true, the per-item buttons (Approve / Reject / Add attachment)
  /// show as busy. Set while the parent's call is in flight.
  final bool reviewing;

  /// Observation note the auditor wrote on the audit sheet when marking
  /// this parameter as Fail. Surfaces the original "why" so the owner can
  /// frame the corrective action without flipping back to the audit.
  final String? auditObservation;

  /// Pool of names the "Responsible person" field offers as type-ahead
  /// suggestions. The owner can still type any name not in the list.
  final List<String> responsiblePersonSuggestions;

  @override
  State<ActionItemWidget> createState() => _ActionItemWidgetState();
}

class _ActionItemWidgetState extends State<ActionItemWidget> {
  late final TextEditingController _correctiveController;
  late final TextEditingController _personController;
  late final TextEditingController _dueDateController;

  @override
  void initState() {
    super.initState();
    _correctiveController =
        TextEditingController(text: widget.item.correctiveAction);
    _personController =
        TextEditingController(text: widget.item.responsiblePerson);
    _dueDateController = TextEditingController(
      text: AppDateUtils.formatDisplay(widget.item.dueDate),
    );
  }

  @override
  void didUpdateWidget(ActionItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.correctiveAction != widget.item.correctiveAction &&
        _correctiveController.text != widget.item.correctiveAction) {
      _correctiveController.text = widget.item.correctiveAction;
    }
    if (oldWidget.item.responsiblePerson != widget.item.responsiblePerson &&
        _personController.text != widget.item.responsiblePerson) {
      _personController.text = widget.item.responsiblePerson;
    }
    if (oldWidget.item.dueDate != widget.item.dueDate) {
      _dueDateController.text =
          AppDateUtils.formatDisplay(widget.item.dueDate);
    }
  }

  @override
  void dispose() {
    _correctiveController.dispose();
    _personController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  bool get _isEdit => widget.mode == ActionItemMode.edit;
  bool get _isReview => widget.mode == ActionItemMode.review;

  @override
  Widget build(BuildContext context) {
    final overDeadline =
        widget.item.dueDate.isAfter(widget.deadline.add(const Duration(days: 1)));

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Banner(
              parameterName: widget.item.parameterName,
              reviewStatus: widget.item.reviewStatus,
              showPill: widget.item.reviewStatus != 'pending' ||
                  widget.item.auditorRemark.isNotEmpty,
              hasValidationError: widget.hasValidationError,
            ),
            const SizedBox(height: 8),
            _AuditObservationBlock(
              observation: (widget.auditObservation ?? '').trim(),
            ),
            if (widget.item.auditorRemark.isNotEmpty) ...[
              const SizedBox(height: 8),
              _AuditorRemarkBlock(
                remark: widget.item.auditorRemark,
                reviewer: widget.item.reviewedBy?.name,
                reviewedAt: widget.item.reviewedAt,
                status: widget.item.reviewStatus,
              ),
            ],
            const SizedBox(height: 10),
            if (_isEdit)
              _EditFields(
                item: widget.item,
                deadline: widget.deadline,
                overDeadline: overDeadline,
                hasValidationError: widget.hasValidationError,
                correctiveController: _correctiveController,
                personController: _personController,
                dueDateController: _dueDateController,
                personSuggestions: widget.responsiblePersonSuggestions,
                onChanged: widget.onChanged,
              )
            else
              _ReadOnlyFields(item: widget.item),

            // Auditor review controls — only render when the screen is in
            // review mode AND the parent has wired an onReview callback.
            if (_isReview && widget.onReview != null) ...[
              const SizedBox(height: 10),
              _ReviewActions(
                current: widget.item.reviewStatus,
                busy: widget.reviewing,
                onApprove: () => _promptAndReview('approved'),
                onReject: () => _promptAndReview('rejected'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Opens the remark dialog. For 'rejected' the remark is required; for
  /// 'approved' it's optional.
  Future<void> _promptAndReview(String reviewStatus) async {
    final remark = await showDialog<String>(
      context: context,
      builder: (ctx) => _ReviewRemarkDialog(
        reviewStatus: reviewStatus,
        parameterName: widget.item.parameterName,
        initial: widget.item.auditorRemark,
      ),
    );
    if (remark == null) return;
    await widget.onReview!(reviewStatus, remark);
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.parameterName,
    required this.reviewStatus,
    required this.showPill,
    required this.hasValidationError,
  });

  final String parameterName;
  final String reviewStatus;
  final bool showPill;
  final bool hasValidationError;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.redTint,
        borderRadius: BorderRadius.circular(8),
        border: hasValidationError
            ? Border.all(color: AppColors.danger, width: 1.4)
            : null,
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 16, color: AppColors.danger),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              parameterName,
              style: AppTextStyles.medium13.copyWith(color: AppColors.danger),
            ),
          ),
          if (showPill) StatusPill(status: reviewStatus),
        ],
      ),
    );
  }
}

/// Read-only label/value grid for auditors + cluster managers. Two columns
/// on wide screens, one on narrow — no fixed-aspect GridView so it sizes
/// naturally to the content.
class _ReadOnlyFields extends StatelessWidget {
  const _ReadOnlyFields({required this.item});

  final ActionItemModel item;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 720;
    final cells = <Widget>[
      _LabelValue(
        label: 'Corrective action',
        value: item.correctiveAction.isEmpty ? '—' : item.correctiveAction,
      ),
      _LabelValue(
        label: 'Responsible person',
        value: item.responsiblePerson.isEmpty ? '—' : item.responsiblePerson,
      ),
      _LabelValue(
        label: 'Due date',
        value: AppDateUtils.formatDisplay(item.dueDate),
      ),
      _LabelValueWidget(
        label: 'Status',
        child: StatusPill(status: item.status),
      ),
    ];

    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < cells.length; i++) ...[
            cells[i],
            if (i != cells.length - 1) const SizedBox(height: 10),
          ],
        ],
      );
    }
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: cells[0]),
              const SizedBox(width: 16),
              Expanded(child: cells[1]),
            ],
          ),
        ),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: cells[2]),
              const SizedBox(width: 16),
              Expanded(child: cells[3]),
            ],
          ),
        ),
      ],
    );
  }
}

class _LabelValue extends StatelessWidget {
  const _LabelValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.medium12.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.body14),
      ],
    );
  }
}

class _LabelValueWidget extends StatelessWidget {
  const _LabelValueWidget({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.medium12.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        child,
      ],
    );
  }
}

/// Owner / Admin edit form. Replaces the previous fixed-aspect GridView with
/// IntrinsicHeight rows so each cell hugs its actual content height — no
/// more 200-pixel blank gaps.
class _EditFields extends StatelessWidget {
  const _EditFields({
    required this.item,
    required this.deadline,
    required this.overDeadline,
    required this.hasValidationError,
    required this.correctiveController,
    required this.personController,
    required this.dueDateController,
    required this.personSuggestions,
    required this.onChanged,
  });

  final ActionItemModel item;
  final DateTime deadline;
  final bool overDeadline;
  final bool hasValidationError;
  final TextEditingController correctiveController;
  final TextEditingController personController;
  final TextEditingController dueDateController;
  final List<String> personSuggestions;
  final ValueChanged<ActionItemModel> onChanged;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 720;

    final corrective = AppInput(
      label: 'Corrective action',
      controller: correctiveController,
      dense: true,
      validator: hasValidationError
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
      onChanged: (value) =>
          onChanged(item.copyWith(correctiveAction: value)),
    );
    final person = _PersonAutocomplete(
      controller: personController,
      suggestions: personSuggestions,
      hasValidationError: hasValidationError,
      onChanged: (value) =>
          onChanged(item.copyWith(responsiblePerson: value)),
    );
    final due = AppInput(
      label: overDeadline
          ? 'Due date (≤ ${AppDateUtils.formatDisplay(deadline)})'
          : 'Due date',
      controller: dueDateController,
      isReadOnly: true,
      dense: true,
      suffixIcon: const Icon(Icons.calendar_today_outlined, size: 16),
      onTap: () async {
        final firstDate = DateTime.now();
        final lastDate =
            deadline.isBefore(firstDate) ? firstDate : deadline;
        final initial = item.dueDate.isBefore(firstDate)
            ? firstDate
            : (item.dueDate.isAfter(lastDate) ? lastDate : item.dueDate);
        final selected = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: firstDate,
          lastDate: lastDate,
        );
        if (selected != null) {
          onChanged(item.copyWith(dueDate: selected));
        }
      },
    );
    final status = AppDropdown<String>(
      label: 'Status',
      value: item.status,
      items: const [
        DropdownMenuItem(value: 'Open', child: Text('Open')),
        DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
        DropdownMenuItem(value: 'Closed', child: Text('Closed')),
      ],
      onChanged: (value) {
        if (value != null) onChanged(item.copyWith(status: value));
      },
    );

    if (!wide) {
      return Column(
        children: [
          corrective,
          const SizedBox(height: 10),
          person,
          const SizedBox(height: 10),
          due,
          const SizedBox(height: 10),
          status,
        ],
      );
    }
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: corrective),
              const SizedBox(width: 12),
              Expanded(child: person),
            ],
          ),
        ),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: due),
              const SizedBox(width: 12),
              Expanded(child: status),
            ],
          ),
        ),
      ],
    );
  }
}

/// Surfaces the auditor's original observation note (captured on the audit
/// sheet against the failed parameter) so the owner can frame the corrective
/// action without flipping back to the audit. Distinct from
/// [_AuditorRemarkBlock], which carries the auditor's review remark.
/// Typeahead-backed "Responsible person" field. Behaves like the regular
/// [AppInput] when there are no suggestions or the user types something not
/// in the list — i.e., free text is always allowed. When the typed prefix
/// matches one or more entries in [suggestions], an overlay shows the top
/// matches so the owner can pick instead of typing the full name.
///
/// Stateful so the [FocusNode] handed to [RawAutocomplete] survives the
/// parent's rebuilds — handing it a fresh node every build broke focus
/// tracking and made the overlay never appear.
class _PersonAutocomplete extends StatefulWidget {
  const _PersonAutocomplete({
    required this.controller,
    required this.suggestions,
    required this.hasValidationError,
    required this.onChanged,
  });

  final TextEditingController controller;
  final List<String> suggestions;
  final bool hasValidationError;
  final ValueChanged<String> onChanged;

  @override
  State<_PersonAutocomplete> createState() => _PersonAutocompleteState();
}

class _PersonAutocompleteState extends State<_PersonAutocomplete> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      optionsBuilder: (value) {
        final query = value.text.trim().toLowerCase();
        if (query.isEmpty) return widget.suggestions.take(8);
        return widget.suggestions
            .where((s) => s.toLowerCase().contains(query))
            .take(8);
      },
      fieldViewBuilder: (ctx, textController, focusNode, onSubmitted) {
        return AppInput(
          label: 'Responsible person',
          hint: widget.suggestions.isEmpty
              ? 'Type the name'
              : 'Search or pick from the list',
          controller: textController,
          focusNode: focusNode,
          dense: true,
          // Real "open dropdown" affordance — clears the existing text
          // (typically the "TBD" placeholder) and re-focuses the field so
          // the autocomplete overlay opens with the full suggestion list
          // instead of zero results from a stale prefix.
          suffixIcon: widget.suggestions.isEmpty
              ? null
              : Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      textController.clear();
                      widget.onChanged('');
                      focusNode.requestFocus();
                    },
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.arrow_drop_down_rounded, size: 22),
                    ),
                  ),
                ),
          validator: widget.hasValidationError
              ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
              : null,
          onChanged: widget.onChanged,
          onSubmitted: (_) => onSubmitted(),
        );
      },
      optionsViewBuilder: (ctx, onSelected, options) {
        // Match the field's width so the overlay doesn't extend past the
        // form column on narrow viewports.
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220, maxWidth: 360),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: options.length,
                itemBuilder: (_, i) {
                  final option = options.elementAt(i);
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.person_outline, size: 18),
                    title: Text(option, style: AppTextStyles.body13),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AuditObservationBlock extends StatelessWidget {
  const _AuditObservationBlock({required this.observation});

  /// Empty string when the auditor didn't write an observation. The widget
  /// renders a muted "Auditor didn't share an observation" placeholder so
  /// the absence is visible rather than the block silently disappearing.
  final String observation;

  @override
  Widget build(BuildContext context) {
    final hasObservation = observation.trim().isNotEmpty;
    final tone = hasObservation ? AppColors.primary : AppColors.textMuted;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: hasObservation ? AppColors.blueTint : AppColors.surface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tone.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_outlined, size: 14, color: tone),
              const SizedBox(width: 6),
              Text(
                'Auditor observation',
                style: AppTextStyles.medium12.copyWith(color: tone),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            hasObservation
                ? observation
                : 'Auditor didn\'t share an observation for this fail point.',
            style: AppTextStyles.body13.copyWith(
              color: hasObservation ? null : AppColors.textSecondary,
              fontStyle: hasObservation ? null : FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditorRemarkBlock extends StatelessWidget {
  const _AuditorRemarkBlock({
    required this.remark,
    required this.reviewer,
    required this.reviewedAt,
    required this.status,
  });

  final String remark;
  final String? reviewer;
  final DateTime? reviewedAt;
  final String status;

  @override
  Widget build(BuildContext context) {
    final isRejected = status == 'rejected';
    final tint = isRejected ? AppColors.redTint : AppColors.amberTint;
    final fg = isRejected ? AppColors.danger : AppColors.warning;

    final meta = StringBuffer();
    if (reviewer != null && reviewer!.isNotEmpty) meta.write(reviewer);
    if (reviewedAt != null) {
      if (meta.isNotEmpty) meta.write(' · ');
      meta.write(AppDateUtils.formatDisplay(reviewedAt!));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isRejected
                    ? Icons.report_gmailerrorred_rounded
                    : Icons.rate_review_outlined,
                size: 14,
                color: fg,
              ),
              const SizedBox(width: 6),
              Text(
                isRejected ? 'Auditor rejected' : 'Auditor remark',
                style: AppTextStyles.medium12.copyWith(color: fg),
              ),
              if (meta.isNotEmpty) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    meta.toString(),
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body11,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(remark, style: AppTextStyles.body13),
        ],
      ),
    );
  }
}

class _ReviewActions extends StatelessWidget {
  const _ReviewActions({
    required this.current,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  final String current;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final isApproved = current == 'approved';
    final isRejected = current == 'rejected';
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: isApproved ? 'Approved' : 'Approve',
            icon: Icons.check_circle_outline,
            variant: isApproved
                ? AppButtonVariant.ghost
                : AppButtonVariant.primary,
            onPressed: busy ? null : onApprove,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppButton(
            label: isRejected ? 'Rejected' : 'Reject',
            icon: Icons.cancel_outlined,
            variant: AppButtonVariant.ghost,
            onPressed: busy ? null : onReject,
          ),
        ),
      ],
    );
  }
}

class _ReviewRemarkDialog extends StatefulWidget {
  const _ReviewRemarkDialog({
    required this.reviewStatus,
    required this.parameterName,
    required this.initial,
  });

  final String reviewStatus;
  final String parameterName;
  final String initial;

  @override
  State<_ReviewRemarkDialog> createState() => _ReviewRemarkDialogState();
}

class _ReviewRemarkDialogState extends State<_ReviewRemarkDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  bool get _isReject => widget.reviewStatus == 'rejected';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (_isReject && value.isEmpty) {
      setState(() => _errorText = 'Remark is required when rejecting.');
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isReject ? 'Reject item' : 'Approve item'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.parameterName, style: AppTextStyles.medium14),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 4,
            decoration: InputDecoration(
              labelText:
                  _isReject ? 'Reason for rejection' : 'Remark (optional)',
              border: const OutlineInputBorder(),
              errorText: _errorText,
            ),
            onChanged: (_) {
              if (_errorText != null) setState(() => _errorText = null);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_isReject ? 'Reject' : 'Approve'),
        ),
      ],
    );
  }
}
