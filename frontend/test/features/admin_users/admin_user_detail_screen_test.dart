import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/features/admin_users/data/admin_user_mock_repository.dart';
import 'package:marinelink/features/admin_users/domain/admin_user.dart';
import 'package:marinelink/features/admin_users/domain/admin_user_repository.dart';
import 'package:marinelink/features/admin_users/presentation/screens/admin_user_detail_screen.dart';

const _dealer = AdminUser(
  id: 'user-dealer-001',
  fullName: 'Đại lý Nguyễn Văn A',
  email: 'daily-a@marinelink.demo',
  phone: '0912345678',
  role: AdminUserRole.user,
  status: AdminUserStatus.active,
  taxCode: '0301234567',
  storeName: 'Cửa hàng Ngư cụ Nguyễn Văn A',
  businessAddress: '25 Nguyễn Tất Thành, Quận 4, TP. Hồ Chí Minh',
);

const _incomplete = AdminUser(
  id: 'user-staff-001',
  fullName: 'Nhân viên Demo',
  email: 'staff@marinelink.demo',
  phone: '0900000001',
  role: AdminUserRole.staff,
  status: AdminUserStatus.active,
);

Future<void> _pump(
  WidgetTester tester,
  AdminUser? user, {
  AdminUserRepository? repository,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(800, 1600);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: AdminUserDetailScreen(user: user, repository: repository),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders full user info including tax code, store, address', (
    tester,
  ) async {
    await _pump(tester, _dealer);

    expect(find.byKey(const Key('adminUserDetailScreen')), findsOneWidget);
    expect(find.text('Đại lý Nguyễn Văn A'), findsOneWidget);
    expect(find.text('0301234567'), findsOneWidget);
    expect(find.text('Cửa hàng Ngư cụ Nguyễn Văn A'), findsOneWidget);
    expect(
      find.text('25 Nguyễn Tất Thành, Quận 4, TP. Hồ Chí Minh'),
      findsOneWidget,
    );
    expect(find.text('daily-a@marinelink.demo'), findsOneWidget);
    expect(find.text('0912345678'), findsOneWidget);
    expect(find.byKey(const Key('adminUserDetailTaxCode')), findsOneWidget);
    expect(find.byKey(const Key('adminUserDetailStoreName')), findsOneWidget);
    expect(
      find.byKey(const Key('adminUserDetailBusinessAddress')),
      findsOneWidget,
    );
  });

  testWidgets('shows placeholder for missing business fields', (tester) async {
    await _pump(tester, _incomplete);

    expect(find.text('Chưa cập nhật'), findsWidgets);
  });

  testWidgets('shows fallback message when user is null', (tester) async {
    await _pump(tester, null);

    expect(find.byKey(const Key('adminUserDetailMissing')), findsOneWidget);
  });

  testWidgets('locks an active account after confirmation', (tester) async {
    final repository = AdminUserMockRepository(initialUsers: [_dealer]);
    await _pump(tester, _dealer, repository: repository);

    // Tài khoản đang hoạt động -> hiện nút Khóa.
    expect(find.byKey(const Key('adminUserLockButton')), findsOneWidget);
    expect(find.byKey(const Key('adminUserUnlockButton')), findsNothing);

    await tester.tap(find.byKey(const Key('adminUserLockButton')));
    await tester.pumpAndSettle();

    // Có hộp thoại xác nhận trước khi khóa.
    expect(find.byKey(const Key('adminUserLockConfirmDialog')), findsOneWidget);
    await tester.tap(find.byKey(const Key('adminUserLockConfirmButton')));
    await tester.pumpAndSettle();

    // Sau khi khóa -> đổi thành nút Mở khóa.
    expect(find.byKey(const Key('adminUserUnlockButton')), findsOneWidget);
    expect(find.byKey(const Key('adminUserLockButton')), findsNothing);
    expect(find.text('Đã khóa tài khoản.'), findsOneWidget);
  });

  testWidgets('cancelling the confirm dialog keeps the account active', (
    tester,
  ) async {
    final repository = AdminUserMockRepository(initialUsers: [_dealer]);
    await _pump(tester, _dealer, repository: repository);

    await tester.tap(find.byKey(const Key('adminUserLockButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('adminUserLockButton')), findsOneWidget);
    expect(find.byKey(const Key('adminUserUnlockButton')), findsNothing);
  });

  testWidgets('unlocks a disabled account without confirmation', (
    tester,
  ) async {
    const locked = AdminUser(
      id: 'user-dealer-002',
      fullName: 'Đại lý Tạm Khóa',
      email: 'disabled@marinelink.demo',
      phone: '0912000000',
      role: AdminUserRole.user,
      status: AdminUserStatus.disabled,
    );
    final repository = AdminUserMockRepository(initialUsers: [locked]);
    await _pump(tester, locked, repository: repository);

    expect(find.byKey(const Key('adminUserUnlockButton')), findsOneWidget);

    await tester.tap(find.byKey(const Key('adminUserUnlockButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('adminUserLockButton')), findsOneWidget);
    expect(find.text('Đã mở khóa tài khoản.'), findsOneWidget);
  });

  testWidgets('shows an error when locking fails', (tester) async {
    // Repo rỗng -> không tìm thấy user -> trả lỗi.
    final repository = AdminUserMockRepository(initialUsers: const []);
    await _pump(tester, _dealer, repository: repository);

    await tester.tap(find.byKey(const Key('adminUserLockButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('adminUserLockConfirmButton')));
    await tester.pumpAndSettle();

    expect(find.text('Không khóa được tài khoản.'), findsOneWidget);
    // Vẫn giữ nút Khóa vì thao tác thất bại.
    expect(find.byKey(const Key('adminUserLockButton')), findsOneWidget);
  });
}
