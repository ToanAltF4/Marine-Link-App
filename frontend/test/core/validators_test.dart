import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('returns null for valid email', () {
      expect(Validators.email('test@example.com'), isNull);
    });

    test('returns error for empty email', () {
      expect(Validators.email(''), isNotNull);
    });

    test('returns error for invalid format', () {
      expect(Validators.email('not-an-email'), isNotNull);
    });
  });

  group('Validators.phone', () {
    test('returns null for valid Vietnamese phone', () {
      expect(Validators.phone('0912345678'), isNull);
    });

    test('returns error for too short phone', () {
      expect(Validators.phone('0912'), isNotNull);
    });
  });

  group('Validators.password', () {
    test('returns null for valid password', () {
      expect(Validators.password('Admin@123'), isNull);
    });

    test('returns error for short password', () {
      expect(Validators.password('abc'), isNotNull);
    });

    test('returns error for empty password', () {
      expect(Validators.password(''), isNotNull);
    });
  });

  group('Validators.quantity', () {
    test('returns null for valid quantity', () {
      expect(Validators.quantity('10', minQuantity: 2), isNull);
    });

    test('returns error below min quantity', () {
      expect(Validators.quantity('1', minQuantity: 2), isNotNull);
    });

    test('returns error for non-number', () {
      expect(Validators.quantity('abc'), isNotNull);
    });
  });
}
