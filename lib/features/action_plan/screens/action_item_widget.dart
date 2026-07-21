import 'dart:convert' show base64Decode;
import 'dart:typed_data' show Uint8List;
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/page_chrome.dart';
import '../../../core/widgets/photo_capture_modal.dart';
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
    this.mode = ActionItemMode.edit,
    this.onReview,
    this.reviewing = false,
    this.auditObservation,
    this.responsiblePersonSuggestions = const [],
    this.onUploadAttachment,
    this.onRemoveAttachment,
    this.uploadingAttachment = false,
  });

  final ActionItemModel item;
  final ValueChanged<ActionItemModel> onChanged;

  /// Uploads one optional evidence file for this point. Non-null enables the
  /// "Add attachment" control (owner, editable item, persisted item id).
  /// Returns true on success; may throw so the capture modal shows the error
  /// inline and stays open for a retry.
  final Future<bool> Function(
    Uint8List bytes,
    String filename,
    String mimeType,
  )? onUploadAttachment;

  /// Removes a previously-uploaded attachment by id. Non-null enables the ×
  /// on each attachment thumbnail.
  final Future<void> Function(String attachmentId)? onRemoveAttachment;

  /// True while an attachment upload for this point is in flight.
  final bool uploadingAttachment;

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

  /// Attaching is offered only when the owner is editing this (persisted)
  /// point and the parent wired an upload handler. Unpersisted items (no id)
  /// can't receive attachments — the endpoint is keyed by item id.
  bool get _canAttach =>
      _isEdit &&
      widget.item.id != null &&
      widget.onUploadAttachment != null;

  /// Opens the capture modal and hands the bytes to the parent uploader.
  /// The modal closes on a non-null return (true) and surfaces any thrown
  /// error inline so the owner can retry without re-picking.
  Future<void> _addAttachment(BuildContext context) async {
    final upload = widget.onUploadAttachment;
    if (upload == null) return;
    await PhotoCaptureModal.show<bool>(
      context,
      title: 'Attachment · ${widget.item.parameterName}',
      front: false,
      onSubmit: (bytes, filename, mimeType) =>
          upload(bytes, filename, mimeType),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            ),
            const SizedBox(height: 8),
            // Once the auditor approves an item the owner / cluster manager
            // can no longer edit it. Surface that lock explicitly so the
            // grayed-out fields aren't read as "broken". Auditor stays in
            // review mode, so we don't show this for them.
            if (widget.item.reviewStatus == 'approved' && !_isReview) ...[
              const _ApprovedLockBanner(),
              const SizedBox(height: 8),
            ],
            _AuditObservationBlock(
              observation: (widget.auditObservation ?? '').trim(),
              evidencePhotoUrls: widget.item.evidencePhotoUrls,
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
                correctiveController: _correctiveController,
                personController: _personController,
                dueDateController: _dueDateController,
                personSuggestions: widget.responsiblePersonSuggestions,
                onChanged: widget.onChanged,
              )
            else
              _ReadOnlyFields(item: widget.item),

            // Optional owner attachments per point. The add/remove controls
            // show only when this card is editable and the item is persisted
            // (has an id); otherwise the strip is view-only so auditors and
            // others can still see the evidence.
            if (_canAttach || widget.item.attachments.isNotEmpty) ...[
              const SizedBox(height: 10),
              _OwnerAttachmentsBlock(
                attachments: widget.item.attachments,
                editable: _canAttach,
                uploading: widget.uploadingAttachment,
                onAdd: () => _addAttachment(context),
                onRemove: widget.onRemoveAttachment,
              ),
            ],

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
  });

  final String parameterName;
  final String reviewStatus;
  final bool showPill;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.redTint,
        borderRadius: BorderRadius.circular(8),
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
    required this.correctiveController,
    required this.personController,
    required this.dueDateController,
    required this.personSuggestions,
    required this.onChanged,
  });

  final ActionItemModel item;
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
      onChanged: (value) =>
          onChanged(item.copyWith(correctiveAction: value)),
    );
    final person = _PersonAutocomplete(
      controller: personController,
      suggestions: personSuggestions,
      onChanged: (value) =>
          onChanged(item.copyWith(responsiblePerson: value)),
    );
    final due = AppInput(
      label: 'Due date',
      controller: dueDateController,
      isReadOnly: true,
      dense: true,
      suffixIcon: const Icon(Icons.calendar_today_outlined, size: 16),
      onTap: () async {
        // No day-limit is enforced — the owner can pick any date from today
        // out to five years ahead. An existing past due date is clamped up to
        // today so the picker can open on a valid initial date.
        final firstDate = DateTime.now();
        final lastDate = firstDate.add(const Duration(days: 365 * 5));
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
    required this.onChanged,
  });

  final TextEditingController controller;
  final List<String> suggestions;
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
      // RawAutocomplete updates the controller's text programmatically when
      // an option is picked, and TextEditingController writes do NOT fire
      // the underlying TextField's onChanged. Without this callback the
      // parent state never learns the user picked anyone → the PATCH sent
      // responsible_person: "" and the server (correctly) preserved the
      // "TBD" auto-seed. Wiring onSelected → widget.onChanged fixes it.
      onSelected: widget.onChanged,
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
  const _AuditObservationBlock({
    required this.observation,
    required this.evidencePhotoUrls,
  });

  /// Empty string when the auditor didn't write an observation. The widget
  /// renders a muted "Auditor didn't share an observation" placeholder so
  /// the absence is visible rather than the block silently disappearing.
  final String observation;
  final List<String> evidencePhotoUrls;

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
          if (evidencePhotoUrls.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: evidencePhotoUrls.length,
                itemBuilder: (context, index) {
                  final url = evidencePhotoUrls[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _EvidenceThumbnail(url: url),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EvidenceThumbnail extends StatelessWidget {
  const _EvidenceThumbnail({required this.url});

  final String url;

  bool get _isDataUrl => url.startsWith('data:');

  Uint8List _decodeDataUrl() {
    final comma = url.indexOf(',');
    return base64Decode(url.substring(comma + 1));
  }

  Widget _buildImage({BoxFit fit = BoxFit.cover}) {
    if (_isDataUrl) {
      try {
        return Image.memory(
          _decodeDataUrl(),
          fit: fit,
          errorBuilder: (ctx, err, st) {
            return Container(
              color: AppColors.redTint,
              alignment: Alignment.center,
              child: Icon(Icons.broken_image_outlined, size: 20, color: AppColors.danger),
            );
          },
        );
      } catch (_) {
        return Container(
          color: AppColors.redTint,
          alignment: Alignment.center,
          child: Icon(Icons.broken_image_outlined, size: 20, color: AppColors.danger),
        );
      }
    }
    return Image.network(
      url,
      fit: fit,
      errorBuilder: (ctx, err, st) {
        return Container(
          color: AppColors.redTint,
          alignment: Alignment.center,
          child: Icon(Icons.broken_image_outlined, size: 20, color: AppColors.danger),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: InteractiveViewer(
                    maxScale: 4.0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildImage(fit: BoxFit.contain),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withValues(alpha: 0.5),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: _buildImage(),
        ),
      ),
    );
  }
}

/// Optional owner evidence-file strip under each action-plan point. When
/// [editable], the owner gets an "Add attachment" button and a × on each
/// file; otherwise it's a read-only strip so auditors/others can see the
/// evidence.
class _OwnerAttachmentsBlock extends StatelessWidget {
  const _OwnerAttachmentsBlock({
    required this.attachments,
    required this.editable,
    required this.uploading,
    required this.onAdd,
    required this.onRemove,
  });

  final List<ActionItemAttachment> attachments;
  final bool editable;
  final bool uploading;
  final VoidCallback onAdd;
  final Future<void> Function(String attachmentId)? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_file_rounded,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                editable ? 'Attachments (optional)' : 'Attachments',
                style: AppTextStyles.medium12
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          if (attachments.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final a in attachments)
                  _AttachmentTile(
                    attachment: a,
                    onRemove: (editable && onRemove != null)
                        ? () => onRemove!(a.id)
                        : null,
                  ),
              ],
            ),
          ],
          if (editable) ...[
            const SizedBox(height: 8),
            _AddAttachmentButton(uploading: uploading, onTap: onAdd),
          ] else if (attachments.isEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'No attachments added.',
              style:
                  AppTextStyles.body12.copyWith(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

/// One attachment in the strip: an image thumbnail (reusing
/// [_EvidenceThumbnail], with tap-to-zoom) or a file icon for non-images
/// (e.g. PDFs), plus an optional × to remove it.
class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({required this.attachment, required this.onRemove});

  final ActionItemAttachment attachment;
  final VoidCallback? onRemove;

  bool get _isImage {
    final m = attachment.mimeType?.toLowerCase() ?? '';
    if (m.startsWith('image/')) return true;
    if (m.isNotEmpty) return false;
    final u = attachment.url.toLowerCase();
    return u.startsWith('data:image') ||
        u.contains('.jpg') ||
        u.contains('.jpeg') ||
        u.contains('.png') ||
        u.contains('.webp');
  }

  @override
  Widget build(BuildContext context) {
    final Widget tile = _isImage
        ? _EvidenceThumbnail(url: attachment.url)
        : Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
              color: AppColors.surface3,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.description_outlined,
                size: 24, color: AppColors.textSecondary),
          );
    if (onRemove == null) return tile;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        tile,
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 1.5),
              ),
              child: const Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddAttachmentButton extends StatelessWidget {
  const _AddAttachmentButton({required this.uploading, required this.onTap});

  final bool uploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: uploading ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: AppColors.primary.withValues(alpha: 0.30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (uploading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary),
              )
            else
              const Icon(Icons.add_photo_alternate_outlined,
                  size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              uploading ? 'Uploading…' : 'Add attachment',
              style:
                  AppTextStyles.medium13.copyWith(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Green "locked from edits" banner shown on items the auditor has
/// already approved. Renders for the project owner / admin / cluster
/// manager — auditors keep their review controls and don't see this.
class _ApprovedLockBanner extends StatelessWidget {
  const _ApprovedLockBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.greenTint,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.32)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, size: 14, color: AppColors.success),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Approved by auditor — locked from further edits.',
              style: AppTextStyles.medium12.copyWith(color: AppColors.success),
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
    final isApproved = status == 'approved';
    final tint = isRejected
        ? AppColors.redTint
        : isApproved
            ? AppColors.greenTint
            : AppColors.amberTint;
    final fg = isRejected
        ? AppColors.danger
        : isApproved
            ? AppColors.success
            : AppColors.warning;

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
                    : isApproved
                        ? Icons.check_circle_outline
                        : Icons.rate_review_outlined,
                size: 14,
                color: fg,
              ),
              const SizedBox(width: 6),
              Text(
                isRejected
                    ? 'Auditor rejected'
                    : isApproved
                        ? 'Auditor approved'
                        : 'Auditor remark',
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
