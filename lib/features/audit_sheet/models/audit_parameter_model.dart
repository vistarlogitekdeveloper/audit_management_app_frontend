import '../../../core/utils/helpers.dart';

class AuditParameterModel {
  const AuditParameterModel({
    required this.index,
    required this.name,
    this.result,
    this.remark = '',
    this.imageUrls = const [],
  });

  final int index;
  final String name;
  final String? result;
  final String remark;

  /// Presigned HTTPS URLs the backend has stored for this parameter. Empty
  /// when nothing has been uploaded yet. The list is rebuilt on every fetch
  /// — pending (locally picked, not-yet-uploaded) photos live on
  /// [AuditRowState] instead.
  final List<String> imageUrls;

  AuditParameterModel copyWith({
    int? index,
    String? name,
    String? result,
    String? remark,
    List<String>? imageUrls,
  }) {
    return AuditParameterModel(
      index: index ?? this.index,
      name: name ?? this.name,
      result: result ?? this.result,
      remark: remark ?? this.remark,
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }

  factory AuditParameterModel.fromJson(Map<String, dynamic> json) {
    return AuditParameterModel(
      index: json['index'] != null
          ? AppHelpers.parseInt(json['index'])
          : AppHelpers.parseInt(json['param_index']),
      name: json['name']?.toString() ?? json['param_name']?.toString() ?? '',
      result: json['result']?.toString(),
      remark: json['remark']?.toString() ?? '',
      imageUrls: _parseImageUrls(json),
    );
  }

  Map<String, dynamic> toJson() => {
        'index': index,
        'name': name,
        'result': result,
        'remark': remark,
        'image_urls': imageUrls,
      };

  /// Backend ships photo references in any of three shapes depending on
  /// vintage:
  ///   * legacy single — `image_url: "https://..."` (one photo per row)
  ///   * presigned array — `image_urls: ["https://...", ...]`
  ///   * structured array — `images: [{ presigned_url, image_url, s3_uri, ... }]`
  ///   * base64 data URL — `data:image/jpeg;base64,...` (DB storage fallback
  ///     used when the server has no S3 bucket configured)
  /// We accept all shapes so a backend rollout (or rollback) doesn't blank
  /// out the thumbnail strip. `s3://` canonicals are dropped because the
  /// browser / Flutter can't render them.
  static List<String> _parseImageUrls(Map<String, dynamic> json) {
    final out = <String>[];
    void addIfValid(Object? value) {
      if (value is String &&
          (value.startsWith('http') || value.startsWith('data:'))) {
        out.add(value);
      }
    }

    final flat = json['image_urls'];
    if (flat is List) {
      for (final entry in flat) {
        addIfValid(entry);
      }
    }

    final structured = json['images'];
    if (structured is List) {
      for (final entry in structured) {
        if (entry is Map) {
          addIfValid(entry['presigned_url'] ??
              entry['url'] ??
              entry['image_url']);
        } else {
          addIfValid(entry);
        }
      }
    }

    if (out.isEmpty) {
      addIfValid(json['image_url']);
    }
    return out;
  }
}
