import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/features/auth/data/auth_dto.dart';

void main() {
  group('UserDto.fromJson', () {
    test('parses a full user payload', () {
      final dto = UserDto.fromJson(const {
        'id': 'u-1',
        'fullName': 'Nguyen Van A',
        'email': 'a@example.com',
        'phone': '0912345678',
        'status': 'ACTIVE',
        'roles': ['USER'],
      });

      expect(dto.phone, '0912345678');
      expect(dto.toDomain().fullName, 'Nguyen Van A');
    });

    test('tolerates a Google account with no phone (field omitted)', () {
      // The API omits null fields (Jackson non_null), so a Google sign-up user
      // arrives without "phone" — must not throw a Null-as-String cast error.
      final dto = UserDto.fromJson(const {
        'id': 'u-2',
        'fullName': 'Google User',
        'email': 'google@gmail.com',
        'status': 'ACTIVE',
        'roles': ['USER'],
      });

      expect(dto.phone, '');
      expect(dto.email, 'google@gmail.com');
      expect(dto.toDomain().isUser, isTrue);
    });
  });
}
