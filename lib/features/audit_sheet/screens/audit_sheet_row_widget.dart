import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_sheet_header.dart';
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
    required this.imagePath,
    required this.onImagePicked,
    this.showValidation = false,
    this.isReadOnly = false,
  });

  final int index;
  final String parameterName;
  final String? selectedResult;
  final ValueChanged<String> onResultChanged;
  final TextEditingController remarkController;
  final ValueChanged<String> onRemarkChanged;
  final String? imagePath;
  final ValueChanged<ImageSourceType> onImagePicked;
  final bool showValidation;
  final bool isReadOnly;

  @override
  State<AuditRowWidget> createState() => _AuditRowWidgetState();
}

class _AuditRowWidgetState extends State<AuditRowWidget> {
  // Anchors the desktop popup menu directly under the evidence button so the
  // picker doesn't fly to the bottom of the screen on a wide viewport.
  final GlobalKey _evidenceKey = GlobalKey();

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
                const SizedBox(height: 14),
                const _FieldLabel(
                  icon: Icons.image_outlined,
                  label: 'Evidence photo',
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _EvidenceControl(
                      key: _evidenceKey,
                      imagePath: widget.imagePath,
                      isReadOnly: widget.isReadOnly,
                      onTap: widget.isReadOnly ? null : _pickPhoto,
                    ),
                    const Spacer(),
                    if (widget.selectedResult != null)
                      StatusPill(status: widget.selectedResult!),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPhoto() async {
    // On phones a modal bottom sheet is the natural pattern. On a desktop /
    // wide viewport that sheet slides up from the screen bottom, far from
    // the row's button — anchor a popup menu directly under the button
    // instead so the choice appears right where you tapped.
    final isCompact = MediaQuery.sizeOf(context).width < 600;
    final source = isCompact
        ? await _pickFromBottomSheet()
        : await _pickFromAnchoredMenu();
    if (source != null) widget.onImagePicked(source);
  }

  Future<ImageSourceType?> _pickFromBottomSheet() {
    return showModalBottomSheet<ImageSourceType>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 4, 0),
              child: AppSheetHeader(title: 'Add photo'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take Photo'),
              onTap: () => Navigator.of(ctx).pop(ImageSourceType.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.of(ctx).pop(ImageSourceType.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<ImageSourceType?> _pickFromAnchoredMenu() {
    final buttonBox =
        _evidenceKey.currentContext?.findRenderObject() as RenderBox?;
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (buttonBox == null || overlayBox == null) {
      // Couldn't anchor — fall back so a click never appears broken.
      return _pickFromBottomSheet();
    }
    final topLeft = buttonBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    final size = buttonBox.size;
    final position = RelativeRect.fromLTRB(
      topLeft.dx,
      topLeft.dy + size.height + 4,
      overlayBox.size.width - topLeft.dx - size.width,
      overlayBox.size.height - topLeft.dy - size.height,
    );
    return showMenu<ImageSourceType>(
      context: context,
      position: position,
      items: const [
        PopupMenuItem(
          value: ImageSourceType.camera,
          child: Row(
            children: [
              Icon(Icons.photo_camera_outlined, size: 18),
              SizedBox(width: 10),
              Text('Take Photo'),
            ],
          ),
        ),
        PopupMenuItem(
          value: ImageSourceType.gallery,
          child: Row(
            children: [
              Icon(Icons.photo_library_outlined, size: 18),
              SizedBox(width: 10),
              Text('Choose from Gallery'),
            ],
          ),
        ),
      ],
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

/// "Add photo" affordance / evidence thumbnail. Tapping (when editable)
/// re-opens the picker so an existing photo can be replaced.
class _EvidenceControl extends StatelessWidget {
  const _EvidenceControl({
    super.key,
    required this.imagePath,
    required this.isReadOnly,
    required this.onTap,
  });

  final String? imagePath;
  final bool isReadOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final path = imagePath;

    if (path == null) {
      if (isReadOnly) {
        return Row(
          children: [
            Icon(Icons.image_not_supported_outlined,
                size: 18, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Text('No evidence', style: AppTextStyles.body12),
          ],
        );
      }
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.blueTint,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_a_photo_outlined,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Add photo',
                style: AppTextStyles.medium13.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // On web the picker hands back a blob: URL (and dart:io File doesn't
    // exist there at runtime), so Image.file would crash. Always render via
    // Image.network on web — it handles blob: and http(s) the same way.
    final thumb = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: (kIsWeb || path.startsWith('http'))
          ? Image.network(path, width: 60, height: 60, fit: BoxFit.cover)
          : Image.file(File(path), width: 60, height: 60, fit: BoxFit.cover),
    );

    if (isReadOnly) return thumb;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          thumb,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: const Icon(Icons.edit_rounded,
                  size: 12, color: AppColors.white),
            ),
          ),
        ],
      ),
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
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
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

enum ImageSourceType { camera, gallery }
