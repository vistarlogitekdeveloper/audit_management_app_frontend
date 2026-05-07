import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_service.dart';
import '../../audit_sheet/services/audit_sheet_service.dart';

final reviewProvider = ChangeNotifierProvider<ReviewProvider>(
  (ref) => ReviewProvider(
    AuditSheetService(ref.watch(apiServiceProvider)),
  ),
);

class ReviewProvider extends ChangeNotifier {
  ReviewProvider(this._service);

  final AuditSheetService _service;
  bool isLoading = false;
  String ownerRemarks = '';

  void setOwnerRemarks(String value) {
    ownerRemarks = value;
    notifyListeners();
  }

  Future<AcknowledgeResult> acknowledge(String auditId) async {
    isLoading = true;
    notifyListeners();
    try {
      return await _service.acknowledgeSheet(auditId, ownerRemarks);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
