import 'dart:typed_data';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Bottom-sheet capture flow:
///
///   1. Open → Camera button OR Gallery/File button.
///   2. Tap Camera → native camera fires (front or rear depending on [front]).
///      Tap Gallery → system photo-picker / file dialog.
///   3. Photo returns → inline preview + Retake / Gallery / Submit buttons.
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

  /// Pixel cap for the captured image's longest dimension. Spec says
  /// 1280 for selfies, 1600 for documents — keeps JPEG bytes in the
  /// 200-400 KB band without a separate compression plugin.
  final int maxWidth;

  /// Caller-provided submit handler. Receives bytes, filename, and the
  /// resolved MIME type of the picked file. Returning null keeps the modal
  /// open (caller decides). Returning non-null pops the modal with
  /// that value. Throwing shows the error inline.
  final Future<Object?> Function(
    Uint8List bytes,
    String filename,
    String mimeType,
  ) onSubmit;

  /// Convenience that wires up `showModalBottomSheet` with the
  /// sensible defaults for this flow (full-height capable,
  /// non-dismissible so an accidental swipe doesn't lose the captured
  /// bytes mid-upload, transparent background so we own the corners).
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
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => PhotoCaptureModal(
        title: title,
        front: front,
        maxWidth: maxWidth ?? (front ? 1280 : 1600),
        onSubmit: (b, f, m) => onSubmit(b, f, m),
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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header row
                Row(
                  children: [
                    Expanded(
                      child: Text(widget.title, style: AppTextStyles.title16),
                    ),
                    IconButton(
                      onPressed:
                          _busy ? null : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Preview area
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: _bytes == null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 52,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Take a photo or choose from gallery',
                                  style: AppTextStyles.body12.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.memory(_bytes!, fit: BoxFit.cover),
                          ),
                  ),
                ),
                // Inline error banner
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.redTint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 16,
                          color: AppColors.danger,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: AppTextStyles.medium12.copyWith(
                              color: AppColors.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                // Action buttons row
                Row(
                  children: [
                    // Camera button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _capture,
                        icon: const Icon(Icons.camera_alt_rounded, size: 18),
                        label: Text(
                          _bytes == null ? 'Camera' : 'Retake',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Gallery / file picker button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _pickFromGallery,
                        icon: const Icon(
                          Icons.photo_library_outlined,
                          size: 18,
                        ),
                        label: const Text(
                          'Gallery',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Submit / upload button
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: (_bytes == null || _busy) ? null : _submit,
                        icon: _busy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.cloud_upload_rounded, size: 18),
                        label: Text(_busy ? 'Uploading…' : 'Submit'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
