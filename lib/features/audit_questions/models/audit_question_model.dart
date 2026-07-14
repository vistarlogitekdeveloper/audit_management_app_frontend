import '../../../core/utils/helpers.dart';

/// An admin-managed audit point ("question") from the backend master list.
///
/// [paramIndex] is the stable, immutable join key that ties this question to
/// answers on every audit sheet (audit_parameters.param_index). It is assigned
/// server-side and never changes or gets reused — so editing/deactivating a
/// question never rewrites historical audits. [sortOrder] controls display
/// order and can change freely via reorder.
class AuditQuestionModel {
  const AuditQuestionModel({
    required this.id,
    required this.paramIndex,
    required this.name,
    this.description,
    this.sortOrder = 0,
    this.isActive = true,
  });

  final String id;
  final int paramIndex;
  final String name;
  final String? description;
  final int sortOrder;
  final bool isActive;

  AuditQuestionModel copyWith({
    String? name,
    String? description,
    int? sortOrder,
    bool? isActive,
  }) {
    return AuditQuestionModel(
      id: id,
      paramIndex: paramIndex,
      name: name ?? this.name,
      description: description ?? this.description,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
    );
  }

  factory AuditQuestionModel.fromJson(Map<String, dynamic> json) {
    final desc = json['description']?.toString();
    return AuditQuestionModel(
      id: json['id']?.toString() ?? '',
      paramIndex: AppHelpers.parseInt(json['param_index']),
      name: json['name']?.toString() ?? '',
      description: (desc == null || desc.isEmpty) ? null : desc,
      sortOrder: AppHelpers.parseInt(json['sort_order']),
      isActive: json['is_active'] != false,
    );
  }
}
