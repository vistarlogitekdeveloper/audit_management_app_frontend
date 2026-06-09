import 'package:audit_management_app_frontend/features/audit_sheet/models/audit_parameter_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses param_index / param_name fallbacks', () {
    final p = AuditParameterModel.fromJson({
      'param_index': 7,
      'param_name': 'Safety',
      'result': 'pass',
      'remark': 'ok',
    });
    expect(p.index, 7);
    expect(p.name, 'Safety');
    expect(p.result, 'pass');
    expect(p.remark, 'ok');
  });
}
