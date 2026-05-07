import '../../audit_sheet/models/audit_sheet_model.dart';

class ReviewModel {
  const ReviewModel({
    required this.sheet,
    required this.failPoints,
  });

  final AuditSheetModel sheet;
  final int failPoints;
}
