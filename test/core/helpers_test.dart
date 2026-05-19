import 'package:audit_management_app_frontend/core/utils/helpers.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression tests for the HIGH bug: AppHelpers.getInitials crashed with a
/// RangeError on empty / whitespace-only names (UserModel defaults name to '').
/// Plus the safe JSON coercion helpers added for the unsafe-cast fixes.
void main() {
  group('AppHelpers.getInitials', () {
    test('returns "?" for an empty string instead of throwing', () {
      expect(AppHelpers.getInitials(''), '?');
    });

    test('returns "?" for a whitespace-only string', () {
      expect(AppHelpers.getInitials('   '), '?');
    });

    test('single name -> first letter, upper-cased', () {
      expect(AppHelpers.getInitials('alice'), 'A');
    });

    test('first + last initials', () {
      expect(AppHelpers.getInitials('Jane Doe'), 'JD');
    });

    test('collapses repeated/leading/trailing spaces', () {
      expect(AppHelpers.getInitials('  John   Quincy   Adams  '), 'JA');
    });
  });

  group('AppHelpers.asStringMap', () {
    test('passes through a String-keyed map', () {
      expect(AppHelpers.asStringMap({'a': 1}), {'a': 1});
    });

    test('converts a dynamic-keyed map (decoder shape) to String-keyed', () {
      final dynamic raw = <dynamic, dynamic>{'name': 'x'};
      final result = AppHelpers.asStringMap(raw);
      expect(result, isA<Map<String, dynamic>>());
      expect(result!['name'], 'x');
    });

    test('returns null for a String (legacy flat shape) instead of throwing',
        () {
      expect(AppHelpers.asStringMap('Jane Doe'), isNull);
    });

    test('returns null for null / list', () {
      expect(AppHelpers.asStringMap(null), isNull);
      expect(AppHelpers.asStringMap([1, 2]), isNull);
    });
  });

  group('AppHelpers.mapList', () {
    test('maps a list of maps', () {
      final out = AppHelpers.mapList<String>(
        [
          {'v': 'a'},
          {'v': 'b'},
        ],
        (m) => m['v'].toString(),
      );
      expect(out, ['a', 'b']);
    });

    test('skips non-map elements instead of throwing', () {
      final out = AppHelpers.mapList<String>(
        [
          {'v': 'a'},
          null,
          'oops',
          {'v': 'b'},
        ],
        (m) => m['v'].toString(),
      );
      expect(out, ['a', 'b']);
    });

    test('returns empty list when value is not a list', () {
      expect(AppHelpers.mapList<String>(null, (m) => ''), isEmpty);
      expect(AppHelpers.mapList<String>('nope', (m) => ''), isEmpty);
    });
  });
}
