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

  /// When true, the Approve / Reject buttons show a progress spinner and
  /// become non-tappable. Set while the parent's review call is in flight.
  final bool reviewing;

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
      padding: const EdgeInsets.only(bottom: 12),
      child: AppPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fail-point banner + review-status pill on the right
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.redTint,
                borderRadius: BorderRadius.circular(8),
                border: widget.hasValidationError
                    ? Border.all(color: AppColors.danger, width: 1.4)
                    : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Fail: ${widget.item.parameterName}',
                      style: AppTextStyles.medium13
                          .copyWith(color: AppColors.danger),
                    ),
                  ),
                  if (widget.item.reviewStatus != 'pending' ||
                      widget.item.auditorRemark.isNotEmpty)
                    StatusPill(status: widget.item.reviewStatus),
                ],
              ),
            ),

            // Auditor remark + who reviewed when. Always visible if present —
            // owners and cluster managers see exactly what the auditor said.
            if (widget.item.auditorRemark.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _AuditorRemarkBlock(
                  remark: widget.item.auditorRemark,
                  reviewer: widget.item.reviewedBy?.name,
                  reviewedAt: widget.item.reviewedAt,
                  status: widget.item.reviewStatus,
                ),
              ),

            const SizedBox(height: 14),
            // Edit mode is the only path that needs interactive inputs.
            // Reviewers / read-only viewers see plain label-value rows so
            // there's no ambiguity that the data is theirs to change.
            if (_isEdit)
              _EditFields(
                item: widget.item,
                deadline: widget.deadline,
                overDeadline: overDeadline,
                hasValidationError: widget.hasValidationError,
                correctiveController: _correctiveController,
                personController: _personController,
                dueDateController: _dueDateController,
                onChanged: widget.onChanged,
              )
            else
              _ReadOnlyFields(item: widget.item),

            // Auditor review controls — only render when the screen is in
            // review mode AND the parent has wired an onReview callback.
            if (_isReview && widget.onReview != null) ...[
              const SizedBox(height: 14),
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
    // Dialog returns null if cancelled; for rejected an empty string is
    // also treated as cancel because the dialog enforces a non-empty remark.
    if (remark == null) return;
    await widget.onReview!(reviewStatus, remark);
  }
}

/// Two-column display block shown to auditors and other read-only viewers.
/// Pure label + value, no input chrome — there's nothing for them to edit.
class _ReadOnlyFields extends StatelessWidget {
  const _ReadOnlyFields({required this.item});

  final ActionItemModel item;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 900;
    final rows = <Widget>[
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
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i != rows.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    }
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: rows[0]),
            const SizedBox(width: 16),
            Expanded(child: rows[1]),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: rows[2]),
            const SizedBox(width: 16),
            Expanded(child: rows[3]),
          ],
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
          style: AppTextStyles.medium13.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
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
          style: AppTextStyles.medium13.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

/// Owner / Admin edit form — the original 2-column input grid. Pulled out
/// of the main widget so the build method can branch cleanly on mode.
class _EditFields extends StatelessWidget {
  const _EditFields({
    required this.item,
    required this.deadline,
    required this.overDeadline,
    required this.hasValidationError,
    required this.correctiveController,
    required this.personController,
    required this.dueDateController,
    required this.onChanged,
  });

  final ActionItemModel item;
  final DateTime deadline;
  final bool overDeadline;
  final bool hasValidationError;
  final TextEditingController correctiveController;
  final TextEditingController personController;
  final TextEditingController dueDateController;
  final ValueChanged<ActionItemModel> onChanged;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: MediaQuery.of(context).size.width > 900 ? 2 : 1,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 3.2,
      children: [
        AppInput(
          label: 'Corrective action',
          controller: correctiveController,
          validator: hasValidationError
              ? (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null
              : null,
          onChanged: (value) =>
              onChanged(item.copyWith(correctiveAction: value)),
        ),
        AppInput(
          label: 'Responsible person',
          controller: personController,
          validator: hasValidationError
              ? (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null
              : null,
          onChanged: (value) =>
              onChanged(item.copyWith(responsiblePerson: value)),
        ),
        AppInput(
          label: overDeadline
              ? 'Due date (must be ≤ ${AppDateUtils.formatDisplay(deadline)})'
              : 'Due date',
          controller: dueDateController,
          isReadOnly: true,
          suffixIcon: const Icon(Icons.calendar_today_outlined),
          onTap: () async {
            final firstDate = DateTime.now();
            final lastDate =
                deadline.isBefore(firstDate) ? firstDate : deadline;
            final initial = item.dueDate.isBefore(firstDate)
                ? firstDate
                : (item.dueDate.isAfter(lastDate)
                    ? lastDate
                    : item.dueDate);
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
        ),
        AppDropdown<String>(
          label: 'Status',
          value: item.status,
          items: const [
            DropdownMenuItem(value: 'Open', child: Text('Open')),
            DropdownMenuItem(
                value: 'In Progress', child: Text('In Progress')),
            DropdownMenuItem(value: 'Closed', child: Text('Closed')),
          ],
          onChanged: (value) {
            if (value != null) onChanged(item.copyWith(status: value));
          },
        ),
      ],
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
    // Rejected remarks need to read as a call-to-action for the owner;
    // approved / pending ones are just informational.
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
      padding: const EdgeInsets.all(10),
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
                size: 16,
                color: fg,
              ),
              const SizedBox(width: 6),
              Text(
                isRejected ? 'Auditor rejected' : 'Auditor remark',
                style: AppTextStyles.medium12.copyWith(color: fg),
              ),
              if (meta.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(meta.toString(), style: AppTextStyles.body11),
              ],
            ],
          ),
          const SizedBox(height: 4),
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
