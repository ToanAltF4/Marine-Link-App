import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/features/admin_users/data/admin_user_mock_repository.dart';
import 'package:marinelink/features/admin_users/domain/admin_user.dart';

void main() {
  test(
    'getUsers returns mock users with all roles and pending status',
    () async {
      final repository = AdminUserMockRepository();

      final response = await repository.getUsers();

      expect(response.success, true);
      expect(response.data, isNotNull);
      expect(
        response.data!.map((user) => user.role),
        contains(AdminUserRole.admin),
      );
      expect(
        response.data!.map((user) => user.role),
        contains(AdminUserRole.staff),
      );
      expect(
        response.data!.map((user) => user.role),
        contains(AdminUserRole.user),
      );
      expect(
        response.data!.map((user) => user.status),
        contains(AdminUserStatus.pendingApproval),
      );

      final dealer = response.data!.firstWhere(
        (user) => user.role == AdminUserRole.user,
      );
      expect(dealer.taxCode, isNotNull);
      expect(dealer.storeName, isNotNull);
      expect(dealer.businessAddress, isNotNull);
    },
  );

  test('approveUser updates pending user to active', () async {
    final repository = AdminUserMockRepository(
      initialUsers: const [
        AdminUser(
          id: 'pending-001',
          fullName: 'Đại lý mới',
          email: 'new@marinelink.demo',
          phone: '0911111111',
          role: AdminUserRole.user,
          status: AdminUserStatus.pendingApproval,
        ),
      ],
    );

    final approveResponse = await repository.approveUser('pending-001');
    final listResponse = await repository.getUsers();

    expect(approveResponse.success, true);
    expect(approveResponse.data!.status, AdminUserStatus.active);
    expect(listResponse.data!.single.status, AdminUserStatus.active);
  });

  test('createUser adds an active staff account to the list', () async {
    final repository = AdminUserMockRepository(initialUsers: const []);

    final response = await repository.createUser(
      fullName: 'Nhân viên Mới',
      email: 'nhanvien@marinelink.demo',
      phone: '0987654321',
      password: 'matkhau123',
    );
    final listResponse = await repository.getUsers();

    expect(response.success, true);
    expect(response.data!.role, AdminUserRole.staff);
    expect(response.data!.status, AdminUserStatus.active);
    expect(listResponse.data!.single.email, 'nhanvien@marinelink.demo');
  });

  test('createUser maps the role code and rejects a duplicate email', () async {
    final repository = AdminUserMockRepository(initialUsers: const []);

    final created = await repository.createUser(
      fullName: 'Quản trị Mới',
      email: 'quantri@marinelink.demo',
      phone: '0987654322',
      password: 'matkhau123',
      roleCode: 'ADMIN',
    );
    final duplicate = await repository.createUser(
      fullName: 'Trùng Email',
      email: 'QuanTri@marinelink.demo',
      phone: '0987654323',
      password: 'matkhau123',
    );
    final listResponse = await repository.getUsers();

    expect(created.data!.role, AdminUserRole.admin);
    expect(duplicate.success, false);
    expect(duplicate.message, 'Email đã được sử dụng.');
    expect(listResponse.data!.length, 1);
  });
}
