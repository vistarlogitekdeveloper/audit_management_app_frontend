import 'dart:io';

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
  @override
  Widget build(BuildContext context) {
    final invalid =
        !widget.isReadOnly &&
        widget.showValidation &&
            (widget.selectedResult == null ||
                widget.remarkController.text.trim().isEmpty);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: invalid ? AppColors.danger : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 28,
                child: Text('${widget.index}.', style: AppTextStyles.body11),
              ),
              Expanded(
                child: Text(widget.parameterName, style: AppTextStyles.medium14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PFNToggle(
            selected: widget.selectedResult,
            onSelected: widget.onResultChanged,
            isReadOnly: widget.isReadOnly,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.remarkController,
            maxLines: 2,
            enabled: !widget.isReadOnly,
            onChanged: widget.onRemarkChanged,
            decoration: InputDecoration(
              hintText: 'Add remark',
              errorText: invalid && widget.remarkController.text.trim().isEmpty
                  ? 'Remark is required'
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (!widget.isReadOnly)
                IconButton(
                  onPressed: () async {
                    final source = await showModalBottomSheet<ImageSourceType>(
                      context: context,
                      builder: (context) => SafeArea(
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
                              onTap: () => Navigator.of(context).pop(ImageSourceType.camera),
                            ),
                            ListTile(
                              leading: const Icon(Icons.photo_library_outlined),
                              title: const Text('Choose from Gallery'),
                              onTap: () => Navigator.of(context).pop(ImageSourceType.gallery),
                            ),
                          ],
                        ),
                      ),
                    );
                    if (source != null) widget.onImagePicked(source);
                  },
                  icon: const Icon(Icons.camera_alt_outlined),
                )
              else
                const Icon(Icons.image_outlined, color: AppColors.textMuted, size: 20),
              
              const SizedBox(width: 8),
              if (widget.imagePath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: widget.imagePath!.startsWith('http') 
                    ? Image.network(widget.imagePath!, width: 56, height: 56, fit: BoxFit.cover)
                    : Image.file(
                        File(widget.imagePath!),
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                )
              else if (widget.isReadOnly)
                Text('No image', style: AppTextStyles.body11),

              if (widget.selectedResult != null) ...[
                const Spacer(),
                StatusPill(status: widget.selectedResult!),
              ],
            ],
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
    required this.value,
    required this.selected,
    required this.onSelected,
    required this.selectedColor,
    required this.borderColor,
    required this.textColor,
    this.isReadOnly = false,
  });

  final String label;
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
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? selectedColor : AppColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active ? borderColor : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.medium12.copyWith(
              color: active ? textColor : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

enum ImageSourceType { camera, gallery }
