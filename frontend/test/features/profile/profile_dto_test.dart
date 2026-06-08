import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/features/profile/data/profile_dto.dart';

void main() {
  group('profileFromJson', () {
    test('parses documented profile payload', () {
      final profile = profileFromJson({
        'id': '550e8400-e29b-41d4-a716-446655440002',
        'fullName': 'Nguyen Van A',
        'email': 'daily-a@example.com',
        'phone': '0912345678',
        'status': 'ACTIVE',
        'storeName': 'Hai San A',
        'businessAddress': 'Can Tho',
        'taxCode': '0312345678',
        'avatarUrl': 'https://example.com/avatar.png',
        'roles': ['USER'],
      });

      expect(profile.id, '550e8400-e29b-41d4-a716-446655440002');
      expect(profile.roles, ['USER']);
      expect(profile.businessAddress, 'Can Tho');
      expect(profile.avatarUrl, 'https://example.com/avatar.png');
    });

    test('normalizes numeric ids and single role values', () {
      final profile = profileFromJson({
        'id': 12,
        'fullName': 'Staff',
        'email': 'staff@example.com',
        'phone': '0912345678',
        'role': 'STAFF',
      });

      expect(profile.id, '12');
      expect(profile.status, 'ACTIVE');
      expect(profile.roles, ['STAFF']);
      expect(profile.avatarUrl, isNull);
    });
  });
}
