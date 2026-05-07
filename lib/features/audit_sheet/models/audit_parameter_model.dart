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
      imageUrl: json['imageUrl']?.toString() ?? json['image_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'index': index,
    'name': name,
    'result': result,
    'remark': remark,
    'imageUrl': imageUrl,
  };
}
