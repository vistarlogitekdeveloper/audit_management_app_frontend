import 'package:audit_management_app_frontend/features/audit_sheet/models/audit_parameter_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression for Finding 2 reload display: the backend stores a raw s3://
/// image_url plus a browser-loadable presigned_url. The model must surface
/// the loadable one so the photo renders after a reload.
void main() {
  test('prefers presigned_url over the raw s3:// image_url', () {
    final p = AuditParameterModel.fromJson({
      'param_index': 1,
      'param_name': 'P1',
      'image_url': 's3://bucket/sheets/x.jpg',
      'presigned_url': 'https://cdn.example/x.jpg?sig=abc',
    });
    expect(p.imageUrl, 'https://cdn.example/x.jpg?sig=abc');
  });

  test('falls back to image_url when no presigned URL is supplied', () {
    final p = AuditParameterModel.fromJson({
      'param_index': 2,
      'param_name': 'P2',
      'image_url': 's3://bucket/sheets/y.jpg',
    });
    expect(p.imageUrl, 's3://bucket/sheets/y.jpg');
  });

  test('ignores a non-http presigned value and uses the next loadable key',
      () {
    final p = AuditParameterModel.fromJson({
      'param_index': 3,
      'param_name': 'P3',
      'presigned_url': 's3://not-loadable',
      'signed_url': 'https://cdn.example/z.jpg',
    });
    expect(p.imageUrl, 'https://cdn.example/z.jpg');
  });

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
    expect(p.imageUrl, isNull);
  });
}
