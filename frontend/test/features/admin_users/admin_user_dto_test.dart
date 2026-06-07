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
    });

    expect(user.id, 'user-001');
    expect(user.fullName, 'Đại lý Nguyễn Văn A');
    expect(user.role, AdminUserRole.user);
    expect(user.status, AdminUserStatus.pendingApproval);
  });

  test('adminUserFromJson tolerates missing fields', () {
    final user = adminUserFromJson(<String, dynamic>{});

    expect(user.id, '');
    expect(user.fullName, '');
    expect(user.email, '');
    expect(user.phone, '');
    expect(user.role, AdminUserRole.user);
    expect(user.status, AdminUserStatus.pendingApproval);
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
