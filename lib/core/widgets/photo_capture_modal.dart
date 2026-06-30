import 'dart:typed_data';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Compact card-style bottom sheet capture flow:
///
///   1. Open → small card with Camera and Gallery action tiles.
///   2. Tap Camera → native camera fires (front or rear depending on [front]).
///      Tap Gallery → system photo-picker / file dialog.
///   3. Photo returns → small inline preview + Retake / Submit buttons.
///   4. Submit → calls [onSubmit] with bytes + filename + mimeType; modal
///      closes with the caller's returned value (non-null) or stays open (null).
///
/// Handles:
///   * Android process-death during the camera intent (retrieveLostData,
///     Android-only — guarded so iOS/Web don't throw)
///   * User cancellation (modal stays put, no crash)
///   * Permission denial (try/catch → inline red error)
///   * Web browser cancellation (same path as iOS cancel)
///   * Submit failures (inline error; bytes preserved so user can retry)
class PhotoCaptureModal extends StatefulWidget {
  const PhotoCaptureModal({
    super.key,
    required this.title,
    required this.front,
    required this.maxWidth,
    required this.onSubmit,
  });

  final String title;

  /// True → front camera (selfie). False → rear (document / object).
  final bool front;

  /// Pixel cap for the captured image's longest dimension.
  final int maxWidth;

  /// Caller-provided submit handler.
  final Future<Object?> Function(
    Uint8List bytes,
    String filename,
    String mimeType,
  ) onSubmit;

  /// Convenience that wires up `showModalBottomSheet` as a compact card.
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required bool front,
    int? maxWidth,
    required Future<T?> Function(
      Uint8List bytes,
      String filename,
      String mimeType,
    ) onSubmit,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: PhotoCaptureModal(
            title: title,
            front: front,
            maxWidth: maxWidth ?? (front ? 1280 : 1600),
            onSubmit: (b, f, m) => onSubmit(b, f, m),
          ),
        ),
      ),
    );
  }

  @override
  State<PhotoCaptureModal> createState() => _PhotoCaptureModalState();
}

class _PhotoCaptureModalState extends State<PhotoCaptureModal> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _bytes;
  String? _filename;
  String? _mimeType;
  bool _busy = false;
  String? _error;

  /// Resolves a human-readable MIME type from [xFile]. Prefers
  /// `XFile.mimeType` (populated by image_picker on all platforms);
  /// falls back to the file extension, then `image/jpeg`.
  String _resolveMime(XFile xFile) {
    final declared = xFile.mimeType;
    if (declared != null && declared.contains('/')) return declared;
    final ext = xFile.name.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'heic':
      case 'heif':
        return 'image/heic';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  /// Applies a picked [XFile] to the widget state (shared by both camera
  /// and gallery paths).
  Future<void> _applyPicked(XFile picked) async {
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _bytes = bytes;
      _filename = picked.name.isEmpty
          ? 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg'
          : picked.name;
      _mimeType = _resolveMime(picked);
      _busy = false;
    });
  }

  Future<void> _capture() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      XFile? picked = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice:
            widget.front ? CameraDevice.front : CameraDevice.rear,
        imageQuality: 80,
        maxWidth: widget.maxWidth.toDouble(),
      );

      // Android can kill the process during the camera intent (low
      // memory). retrieveLostData recovers the photo on relaunch.
      // This is Android-only — guarded so iOS/Web don't hit the
      // MissingPluginException path.
      if (picked == null &&
          defaultTargetPlatform == TargetPlatform.android) {
        try {
          final lost = await _picker.retrieveLostData();
          if (!lost.isEmpty &&
              lost.file != null &&
              lost.type == RetrieveType.image) {
            picked = lost.file;
          }
        } catch (_) {
          // No lost data — ignore.
        }
      }

      if (picked == null) {
        // User cancelled — stay on the modal, clear busy.
        if (!mounted) return;
        setState(() => _busy = false);
        return;
      }

      await _applyPicked(picked);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not open camera: $e';
      });
    }
  }

  Future<void> _pickFromGallery() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: widget.maxWidth.toDouble(),
      );

      if (picked == null) {
        // User cancelled — stay on the modal, clear busy.
        if (!mounted) return;
        setState(() => _busy = false);
        return;
      }

      await _applyPicked(picked);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not open gallery: $e';
      });
    }
  }

  Future<void> _submit() async {
    if (_bytes == null || _filename == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await widget.onSubmit(
        _bytes!,
        _filename!,
        _mimeType ?? 'image/jpeg',
      );
      if (!mounted) return;
      if (result != null) {
        Navigator.of(context).pop(result);
        return;
      }
      setState(() => _busy = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Upload failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.14),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ───────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.blueTint,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add_a_photo_outlined,
                        size: 17,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upload Photo',
                            style: AppTextStyles.medium14.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            widget.title,
                            style: AppTextStyles.body12.copyWith(
                              color: AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed:
                          _busy ? null : () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ── Body: action tiles OR preview + actions ───────────────
                if (_bytes == null) ...[
                  // No photo yet → two tall action tiles side by side
                  Row(
                    children: [
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.camera_alt_rounded,
                          label: 'Camera',
                          subtitle: 'Take a new photo',
                          enabled: !_busy,
                          onTap: _capture,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.photo_library_outlined,
                          label: 'Gallery',
                          subtitle: 'Choose from library',
                          enabled: !_busy,
                          onTap: _pickFromGallery,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Photo picked → compact row: small preview + action buttons
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Small square preview
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 90,
                          height: 90,
                          child: Image.memory(
                            _bytes!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Action column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _busy ? null : _capture,
                              icon: const Icon(
                                Icons.camera_alt_rounded,
                                size: 16,
                              ),
                              label: const Text('Retake'),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                textStyle: AppTextStyles.medium12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            OutlinedButton.icon(
                              onPressed: _busy ? null : _pickFromGallery,
                              icon: const Icon(
                                Icons.photo_library_outlined,
                                size: 16,
                              ),
                              label: const Text('Gallery'),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                textStyle: AppTextStyles.medium12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            FilledButton.icon(
                              onPressed:
                                  _busy ? null : _submit,
                              icon: _busy
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.cloud_upload_rounded,
                                      size: 16,
                                    ),
                              label: Text(
                                _busy ? 'Uploading…' : 'Submit',
                              ),
                              style: FilledButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                textStyle: AppTextStyles.medium12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],

                // ── Error banner ─────────────────────────────────────────
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.redTint,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 15,
                          color: AppColors.danger,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: AppTextStyles.body12.copyWith(
                              color: AppColors.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Submit button (shown below tiles when no preview yet) ─
                if (_bytes == null) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 38,
                    child: FilledButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.cloud_upload_rounded, size: 16),
                      label: const Text('Submit'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
  }
}

// ── Small action tile ──────────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: enabled ? AppColors.blueTint : AppColors.greyTint,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled
                ? AppColors.primary.withValues(alpha: 0.25)
                : AppColors.border,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: enabled ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTextStyles.medium12.copyWith(
                color: enabled ? AppColors.primary : AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTextStyles.body10.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
