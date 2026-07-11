import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/features/admin_users/domain/admin_user.dart';
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

Future<void> _pump(WidgetTester tester, AdminUser? user) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(800, 1600);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(home: AdminUserDetailScreen(user: user)),
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
}
