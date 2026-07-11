import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/features/admin_users/data/admin_user_dto.dart';
import 'package:marinelink/features/admin_users/domain/admin_user.dart';

void main() {
  test('adminUserFromJson parses a full payload', () {
    final user = adminUserFromJson({
      'id': 'user-001',
      'fullName': 'Đại lý Nguyễn Văn A',
      'email': 'daily-a@marinelink.demo',
      'phone': '0912345678',
      'role': 'USER',
      'status': 'PENDING_APPROVAL',
      'taxCode': '0301234567',
      'storeName': 'Cửa hàng Ngư cụ Nguyễn Văn A',
      'businessAddress': '25 Nguyễn Tất Thành, Quận 4, TP. Hồ Chí Minh',
      'avatarUrl': 'https://cdn.marinelink.demo/avatars/user-001.png',
    });

    expect(user.id, 'user-001');
    expect(user.fullName, 'Đại lý Nguyễn Văn A');
    expect(user.role, AdminUserRole.user);
    expect(user.status, AdminUserStatus.pendingApproval);
    expect(user.taxCode, '0301234567');
    expect(user.storeName, 'Cửa hàng Ngư cụ Nguyễn Văn A');
    expect(user.businessAddress, '25 Nguyễn Tất Thành, Quận 4, TP. Hồ Chí Minh');
    expect(user.avatarUrl, 'https://cdn.marinelink.demo/avatars/user-001.png');
  });

  test('adminUserFromJson tolerates missing fields', () {
    final user = adminUserFromJson(<String, dynamic>{});

    expect(user.id, '');
    expect(user.fullName, '');
    expect(user.email, '');
    expect(user.phone, '');
    expect(user.role, AdminUserRole.user);
    expect(user.status, AdminUserStatus.pendingApproval);
    expect(user.taxCode, isNull);
    expect(user.storeName, isNull);
    expect(user.businessAddress, isNull);
    expect(user.avatarUrl, isNull);
  });

  test('adminUserFromJson treats blank business fields as null', () {
    final user = adminUserFromJson({
      'id': 'user-002',
      'fullName': 'Nhân viên Demo',
      'taxCode': '   ',
      'storeName': '',
    });

    expect(user.taxCode, isNull);
    expect(user.storeName, isNull);
  });

  test('adminUsersFromJson parses list and string-like values', () {
    final users = adminUsersFromJson({
      'items': [
        {
          'public_id': 123,
          'fullName': 'MarineLink Admin',
          'email': 'admin@marinelink.demo',
          'phone': 900000000,
          'roles': ['ADMIN'],
          'status': 'ACTIVE',
        },
        {
          'publicId': 'staff-001',
          'fullName': 'Nhân viên Demo',
          'email': 'staff@marinelink.demo',
          'phone': '0900000001',
          'roleCode': 'STAFF',
          'status': 'DISABLED',
        },
      ],
    });

    expect(users, hasLength(2));
    expect(users.first.id, '123');
    expect(users.first.phone, '900000000');
    expect(users.first.role, AdminUserRole.admin);
    expect(users.first.status, AdminUserStatus.active);
    expect(users.last.role, AdminUserRole.staff);
    expect(users.last.status, AdminUserStatus.disabled);
  });
}
