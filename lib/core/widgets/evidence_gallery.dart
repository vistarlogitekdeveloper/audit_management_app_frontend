import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_sheet_header.dart';

/// Whether the user picked a photo via the camera or gallery.
///
/// Shared between the audit-sheet row widget and the action-plan item
/// widget — both flow into the same `image_picker` call but need to
/// signal the source independently.
enum ImageSourceType { camera, gallery }

/// 60×60 thumbnail grid + always-visible "Add" tile for staging evidence
/// photos on an audit-sheet row or action-plan item.
///
/// Identical visual language across both surfaces:
///   - each thumbnail has a small red × badge for one-tap removal
///   - the "Add" tile stays inline alongside the thumbs, so multiple
///     photos can be staged in one go
///   - read-only mode drops the × badges and the Add tile; an empty list
///     shows the "No evidence" placeholder
class EvidenceGallery extends StatelessWidget {
  const EvidenceGallery({
    super.key,
    required this.imagePaths,
    required this.isReadOnly,
    required this.onAddTap,
    required this.onRemove,
    this.emptyLabel = 'No evidence',
  });

  /// All photos staged for this row, in upload order.
  final List<String> imagePaths;
  final bool isReadOnly;

  /// Tapped when the user wants to add a new photo. The caller is
  /// responsible for showing the picker (typically via
  /// [pickEvidenceSource] below).
  final VoidCallback? onAddTap;

  /// Removes the photo at the given index (matches [imagePaths] order).
  final ValueChanged<int>? onRemove;

  /// Text shown when the gallery is empty in read-only mode.
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (isReadOnly && imagePaths.isEmpty) {
      return Row(
        children: [
          Icon(Icons.image_not_supported_outlined,
              size: 18, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(emptyLabel, style: AppTextStyles.body12),
        ],
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < imagePaths.length; i++)
          _EvidenceThumb(
            path: imagePaths[i],
            isReadOnly: isReadOnly,
            onRemove: onRemove == null ? null : () => onRemove!(i),
          ),
        if (!isReadOnly) _AddPhotoTile(onTap: onAddTap),
      ],
    );
  }
}

class _EvidenceThumb extends StatelessWidget {
  const _EvidenceThumb({
    required this.path,
    required this.isReadOnly,
    required this.onRemove,
  });

  final String path;
  final bool isReadOnly;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    // On web the picker hands back blob: URLs and dart:io File doesn't
    // exist at runtime, so Image.file would crash. Always render via
    // Image.network on web — it handles blob: and http(s) identically.
    final thumb = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: (kIsWeb || path.startsWith('http'))
          ? Image.network(path, width: 60, height: 60, fit: BoxFit.cover)
          : Image.file(File(path), width: 60, height: 60, fit: BoxFit.cover),
    );

    if (isReadOnly || onRemove == null) return thumb;

    // The × badge sits half outside the thumbnail so it doesn't cover the
    // photo content. The extra 8px on width/height makes room.
    return SizedBox(
      width: 68,
      height: 68,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: 0, top: 8, child: thumb),
          Positioned(
            right: 0,
            top: 0,
            child: Tooltip(
              message: 'Remove photo',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onRemove,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.close_rounded,
                        size: 13, color: AppColors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 60,
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.blueTint,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.36),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_a_photo_outlined,
                size: 18, color: AppColors.primary),
            const SizedBox(height: 2),
            Text(
              'Add',
              style: AppTextStyles.body11.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared picker dispatcher: bottom sheet on phones, popup menu anchored
/// under [anchorKey] on wide viewports. Returns the chosen
/// [ImageSourceType] or null if the user dismissed.
///
/// The caller is responsible for passing the returned source to
/// `image_picker` — this widget only handles the *source choice* UI.
Future<ImageSourceType?> pickEvidenceSource(
  BuildContext context, {
  required GlobalKey anchorKey,
}) async {
  final isCompact = MediaQuery.sizeOf(context).width < 600;
  if (isCompact) return _pickFromBottomSheet(context);
  return _pickFromAnchoredMenu(context, anchorKey) ??
      _pickFromBottomSheet(context);
}

Future<ImageSourceType?> _pickFromBottomSheet(BuildContext context) {
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

Future<ImageSourceType?>? _pickFromAnchoredMenu(
    BuildContext context, GlobalKey anchorKey) {
  final buttonBox =
      anchorKey.currentContext?.findRenderObject() as RenderBox?;
  final overlayBox =
      Overlay.of(context).context.findRenderObject() as RenderBox?;
  if (buttonBox == null || overlayBox == null) return null;

  final topLeft =
      buttonBox.localToGlobal(Offset.zero, ancestor: overlayBox);
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
