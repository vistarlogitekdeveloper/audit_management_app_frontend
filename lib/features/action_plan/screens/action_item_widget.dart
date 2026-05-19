import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/page_chrome.dart';
import '../models/action_plan_model.dart';

class ActionItemWidget extends StatefulWidget {
  const ActionItemWidget({
    super.key,
    required this.item,
    required this.onChanged,
    required this.deadline,
    this.hasValidationError = false,
  });

  final ActionItemModel item;
  final ValueChanged<ActionItemModel> onChanged;

  /// Latest acceptable due date (audit_date + 8 days) for any item.
  final DateTime deadline;

  /// When true, missing/invalid fields are highlighted in red.
  final bool hasValidationError;

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
              child: Text(
                'Fail: ${widget.item.parameterName}'
                '${widget.item.auditorRemark.isEmpty ? '' : ' — ${widget.item.auditorRemark}'}',
                style: AppTextStyles.medium13.copyWith(color: AppColors.danger),
              ),
            ),
            const SizedBox(height: 14),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width > 900 ? 2 : 1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 3.2,
              children: [
                AppInput(
                  label: 'Corrective action',
                  controller: _correctiveController,
                  validator: widget.hasValidationError
                      ? (v) => (v == null || v.trim().isEmpty)
                          ? 'Required'
                          : null
                      : null,
                  onChanged: (value) => widget
                      .onChanged(widget.item.copyWith(correctiveAction: value)),
                ),
                AppInput(
                  label: 'Responsible person',
                  controller: _personController,
                  validator: widget.hasValidationError
                      ? (v) => (v == null || v.trim().isEmpty)
                          ? 'Required'
                          : null
                      : null,
                  onChanged: (value) => widget.onChanged(
                      widget.item.copyWith(responsiblePerson: value)),
                ),
                AppInput(
                  label: overDeadline
                      ? 'Due date (must be ≤ ${AppDateUtils.formatDisplay(widget.deadline)})'
                      : 'Due date',
                  controller: _dueDateController,
                  isReadOnly: true,
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                  onTap: () async {
                    final firstDate = DateTime.now();
                    final lastDate = widget.deadline.isBefore(firstDate)
                        ? firstDate
                        : widget.deadline;
                    final initial = widget.item.dueDate.isBefore(firstDate)
                        ? firstDate
                        : (widget.item.dueDate.isAfter(lastDate)
                            ? lastDate
                            : widget.item.dueDate);
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: initial,
                      firstDate: firstDate,
                      lastDate: lastDate,
                    );
                    if (selected != null) {
                      widget.onChanged(
                          widget.item.copyWith(dueDate: selected));
                    }
                  },
                ),
                AppDropdown<String>(
                  label: 'Status',
                  value: widget.item.status,
                  items: const [
                    DropdownMenuItem(value: 'Open', child: Text('Open')),
                    DropdownMenuItem(
                        value: 'In Progress', child: Text('In Progress')),
                    DropdownMenuItem(value: 'Closed', child: Text('Closed')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      widget.onChanged(widget.item.copyWith(status: value));
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
