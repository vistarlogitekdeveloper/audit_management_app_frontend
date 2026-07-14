import 'dart:convert' show base64Decode;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/photo_capture_modal.dart';
import '../../../core/widgets/status_pill.dart';

/// Signature for the row's "upload one photo" callback. The
/// PhotoCaptureModal hands the parent the raw bytes + filename + mimeType;
/// the parent calls `auditSheetProvider.uploadPhoto(...)` and returns
/// the presigned URL so the modal can close with a confirmation. Throws
/// on upload failure so the modal can surface the message inline.
typedef OnUploadImage = Future<String> Function(
  Uint8List bytes,
  String filename,
  String mimeType,
);

class AuditRowWidget extends StatefulWidget {
  const AuditRowWidget({
    super.key,
    required this.index,
    required this.parameterName,
    this.description,
    required this.selectedResult,
    required this.onResultChanged,
    required this.remarkController,
    required this.onRemarkChanged,
    this.showValidation = false,
    this.isReadOnly = false,
    this.imageUrls = const [],
    this.isUploading = false,
    this.onUploadImage,
    this.onRemoveImage,
  });

  final int index;
  final String parameterName;

  /// The admin-managed "what to check for" text for this point. When null the
  /// widget falls back to the bundled [AppConstants] description keyed by name.
  final String? description;

  final String? selectedResult;
  final ValueChanged<String> onResultChanged;
  final TextEditingController remarkController;
  final ValueChanged<String> onRemarkChanged;
  final bool showValidation;
  final bool isReadOnly;

  /// Presigned HTTPS URLs already stored against this row. Rendered as a
  /// horizontal thumbnail strip below the Remark field.
  final List<String> imageUrls;

  /// True while at least one upload for this row is in flight — disables
  /// the "Attach photo" button and shows an inline spinner.
  final bool isUploading;

  /// Invoked after the user picks a file. Null disables the picker (e.g.
  /// when the sheet is read-only). See [OnUploadImage] for the shape.
  final OnUploadImage? onUploadImage;

  /// Per-thumbnail dismiss. Null disables the × button on thumbnails.
  final ValueChanged<String>? onRemoveImage;

  @override
  State<AuditRowWidget> createState() => _AuditRowWidgetState();
}

class _AuditRowWidgetState extends State<AuditRowWidget> {
  /// Scope description for this parameter (e.g. what evidence to look for).
  /// Null when the parameter has no description, in which case the line is
  /// hidden entirely.
  String? get _description =>
      widget.description ??
      AppConstants.auditParameterDescription(widget.parameterName);

  bool get _answered => widget.selectedResult != null;

  bool get _remarkMissing => widget.remarkController.text.trim().isEmpty;

  bool get _photosEnabled =>
      !widget.isReadOnly &&
      widget.onUploadImage != null &&
      !widget.isUploading;

  Future<void> _openCaptureModal() async {
    final upload = widget.onUploadImage;
    if (!_photosEnabled || upload == null) return;
    // Modal owns the capture / preview / Retake / Submit flow.
    // onSubmit receives bytes + filename + mimeType from the picker and
    // returns the presigned URL; non-null pops the modal so the user
    // lands back on the audit row with the thumbnail already in place.
    await PhotoCaptureModal.show<String>(
      context,
      title: 'Evidence photo · ${widget.parameterName}',
      front: false,
      onSubmit: (bytes, filename, mimeType) async =>
          upload(bytes, filename, mimeType),
    );
  }

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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.parameterName,
                                  style: AppTextStyles.medium14.copyWith(
                                    height: 1.35,
                                  ),
                                ),
                                if (_description != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    _description!,
                                    style: AppTextStyles.body12.copyWith(
                                      color: AppColors.textSecondary,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ],
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
                const SizedBox(height: 14),
                _PhotoBlock(
                  imageUrls: widget.imageUrls,
                  isUploading: widget.isUploading,
                  enabled: _photosEnabled,
                  hidePickerButton: widget.isReadOnly &&
                      widget.onUploadImage == null,
                  onAttachTap: _openCaptureModal,
                  onRemove: widget.onRemoveImage,
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

/// Optional per-question photo strip rendered below the Remark field.
/// Shows server-confirmed thumbnails, a per-row upload spinner, and a
/// "+ Attach photo" button that opens the picker (camera / gallery).
/// Tap × on a thumbnail to drop it from this session — the row still
/// persists the URL until the next sheet GET, so [onRemove] is a local
/// hide rather than a backend delete.
class _PhotoBlock extends StatelessWidget {
  const _PhotoBlock({
    required this.imageUrls,
    required this.isUploading,
    required this.enabled,
    required this.hidePickerButton,
    required this.onAttachTap,
    required this.onRemove,
  });

  final List<String> imageUrls;
  final bool isUploading;
  final bool enabled;
  final bool hidePickerButton;
  final VoidCallback onAttachTap;
  final ValueChanged<String>? onRemove;

  @override
  Widget build(BuildContext context) {
    // Nothing to show: read-only viewer with no photos saved. Hide
    // entirely so the row stays compact when this feature isn't in use.
    if (hidePickerButton && imageUrls.isEmpty && !isUploading) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(
          icon: Icons.photo_camera_outlined,
          label: 'Photos (optional)',
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 76,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              if (!hidePickerButton)
                _AttachTile(
                  enabled: enabled,
                  isUploading: isUploading,
                  onTap: onAttachTap,
                ),
              for (final url in imageUrls)
                _PhotoThumbnail(
                  url: url,
                  onRemove: onRemove == null ? null : () => onRemove!(url),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AttachTile extends StatelessWidget {
  const _AttachTile({
    required this.enabled,
    required this.isUploading,
    required this.onTap,
  });

  final bool enabled;
  final bool isUploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 76,
          height: 76,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled ? AppColors.blueTint : AppColors.greyTint,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: enabled
                  ? AppColors.primary.withValues(alpha: 0.32)
                  : AppColors.border,
              style: BorderStyle.solid,
            ),
          ),
          child: isUploading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      size: 20,
                      color: enabled
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Attach',
                      style: AppTextStyles.medium12.copyWith(
                        color: enabled
                            ? AppColors.primary
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({required this.url, required this.onRemove});

  final String url;
  final VoidCallback? onRemove;

  /// Returns true when [url] is a base64 data URL (stored in DB when S3 is
  /// not configured) rather than a regular https URL.
  bool get _isDataUrl => url.startsWith('data:');

  /// Decodes the base64 payload from a `data:<mime>;base64,<data>` URL.
  Uint8List _decodeDataUrl() {
    final comma = url.indexOf(',');
    return base64Decode(url.substring(comma + 1));
  }

  /// Builds an image widget that works for both data: URLs and network URLs.
  Widget _buildImage({
    BoxFit fit = BoxFit.cover,
    Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
  }) {
    if (_isDataUrl) {
      try {
        return Image.memory(
          _decodeDataUrl(),
          fit: fit,
          errorBuilder: errorBuilder != null
              ? (ctx, err, st) => errorBuilder(ctx, err, st)
              : null,
        );
      } catch (_) {
        return Container(
          color: AppColors.redTint,
          alignment: Alignment.center,
          child: Icon(Icons.broken_image_outlined, size: 22, color: AppColors.danger),
        );
      }
    }
    return Image.network(
      url,
      fit: fit,
      loadingBuilder: (ctx, child, progress) {
        if (progress == null) return child;
        return Container(
          color: AppColors.surface2,
          alignment: Alignment.center,
          child: const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        );
      },
      errorBuilder: errorBuilder != null
          ? (ctx, err, st) => errorBuilder(ctx, err, st)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: SizedBox(
        width: 76,
        height: 76,
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: GestureDetector(
                  onTap: () => _showPreview(context),
                  child: _buildImage(
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, _, __) => Container(
                      color: AppColors.redTint,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 22,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (onRemove != null)
              Positioned(
                top: 2,
                right: 2,
                child: Material(
                  color: AppColors.black.withValues(alpha: 0.55),
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: onRemove,
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showPreview(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.of(ctx).pop(),
          child: InteractiveViewer(
            child: _buildImage(fit: BoxFit.contain),
          ),
        ),
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
