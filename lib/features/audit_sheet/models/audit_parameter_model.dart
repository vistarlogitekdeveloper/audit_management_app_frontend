import '../../../core/utils/helpers.dart';

class AuditParameterModel {
  const AuditParameterModel({
    required this.index,
    required this.name,
    this.result,
    this.remark = '',
    this.imageUrl,
  });

  final int index;
  final String name;
  final String? result;
  final String remark;
  final String? imageUrl;

  AuditParameterModel copyWith({
    int? index,
    String? name,
    String? result,
    String? remark,
    String? imageUrl,
  }) {
    return AuditParameterModel(
      index: index ?? this.index,
      name: name ?? this.name,
      result: result ?? this.result,
      remark: remark ?? this.remark,
      imageUrl: imageUrl ?? this.imageUrl,
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
      // Prefer a browser-loadable (presigned http) URL so the photo renders
      // on reload; the raw s3:// image_url is the last-resort fallback (it
      // isn't directly loadable, but keeps prior behaviour when no presigned
      // URL is supplied).
      imageUrl: _firstLoadableUrl(json) ??
          json['imageUrl']?.toString() ??
          json['image_url']?.toString(),
    );
  }

  static String? _firstLoadableUrl(Map<String, dynamic> json) {
    for (final key in const ['presigned_url', 'signed_url', 'url']) {
      final value = json[key]?.toString();
      if (value != null && value.startsWith('http')) return value;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'index': index,
    'name': name,
    'result': result,
    'remark': remark,
    'imageUrl': imageUrl,
  };
}
