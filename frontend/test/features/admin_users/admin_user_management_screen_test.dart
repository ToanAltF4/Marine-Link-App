import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/app/di/service_locator.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/features/admin_users/domain/admin_user.dart';
import 'package:marinelink/features/admin_users/domain/admin_user_repository.dart';
import 'package:marinelink/features/admin_users/presentation/cubit/admin_user_cubit.dart';
import 'package:marinelink/features/admin_users/presentation/screens/admin_user_management_screen.dart';

class _FakeRepo implements AdminUserRepository {
  final Future<ApiResponse<List<AdminUser>>> Function() listResponder;
  final Future<ApiResponse<AdminUser>> Function(String id) approveResponder;

  _FakeRepo({
    required this.listResponder,
    Future<ApiResponse<AdminUser>> Function(String id)? approveResponder,
  }) : approveResponder =
           approveResponder ??
           ((_) async =>
               const ApiResponse(success: false, message: 'Không duyệt được'));

  @override
  Future<ApiResponse<List<AdminUser>>> getUsers() => listResponder();

  @override
  Future<ApiResponse<AdminUser>> approveUser(String id) => approveResponder(id);
}

const _admin = AdminUser(
  id: 'admin-001',
  fullName: 'MarineLink Admin',
  email: 'admin@marinelink.demo',
  phone: '0900000000',
  role: AdminUserRole.admin,
  status: AdminUserStatus.active,
);

const _staff = AdminUser(
  id: 'staff-001',
  fullName: 'Nhân viên Demo',
  email: 'staff@marinelink.demo',
  phone: '0900000001',
  role: AdminUserRole.staff,
  status: AdminUserStatus.active,
);

const _pending = AdminUser(
  id: 'pending-001',
  fullName: 'Đại lý Chờ Duyệt',
  email: 'pending@marinelink.demo',
  phone: '0911111222',
  role: AdminUserRole.user,
  status: AdminUserStatus.pendingApproval,
);

const _activePending = AdminUser(
  id: 'pending-001',
  fullName: 'Đại lý Chờ Duyệt',
  email: 'pending@marinelink.demo',
  phone: '0911111222',
  role: AdminUserRole.user,
  status: AdminUserStatus.active,
);

void _registerRepo(AdminUserRepository repo) {
  sl.registerFactory<AdminUserCubit>(() => AdminUserCubit(repository: repo));
}

Future<void> _pumpScreen(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(800, 1600);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(const MaterialApp(home: AdminUserManagementScreen()));
}

void main() {
  setUp(() async => sl.reset());
  tearDown(() async => sl.reset());

  testWidgets('shows loading indicator while fetching users', (tester) async {
    final completer = Completer<ApiResponse<List<AdminUser>>>();
    _registerRepo(_FakeRepo(listResponder: () => completer.future));

    await _pumpScreen(tester);
    await tester.pump();

    expect(find.byKey(const Key('adminUsersLoading')), findsOneWidget);
    expect(find.byKey(const Key('adminUsersList')), findsNothing);

    completer.complete(
      const ApiResponse(success: true, message: 'OK', data: [_admin]),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('adminUsersLoading')), findsNothing);
  });

  testWidgets('renders user list, filters, and approve action', (tester) async {
    _registerRepo(
      _FakeRepo(
        listResponder: () async => const ApiResponse(
          success: true,
          message: 'OK',
          data: [_admin, _staff, _pending],
        ),
        approveResponder: (_) async => const ApiResponse(
          success: true,
          message: 'OK',
          data: _activePending,
        ),
      ),
    );

    await _pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('adminUsersSummaryCard')), findsOneWidget);
    expect(find.byKey(const Key('adminUserCard_admin-001')), findsOneWidget);
    expect(find.byKey(const Key('adminUserCard_staff-001')), findsOneWidget);
    expect(find.byKey(const Key('adminUserCard_pending-001')), findsOneWidget);
    expect(
      find.byKey(const Key('adminUserApproveButton_pending-001')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('adminUserRoleFilterUser')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('adminUserCard_admin-001')), findsNothing);
    expect(find.byKey(const Key('adminUserCard_pending-001')), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('adminUserApproveButton_pending-001')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Đang hoạt động'), findsWidgets);
    expect(
      find.byKey(const Key('adminUserApproveButton_pending-001')),
      findsNothing,
    );
  });

  testWidgets('shows empty state when there are no users', (tester) async {
    _registerRepo(
      _FakeRepo(
        listResponder: () async =>
            const ApiResponse(success: true, message: 'OK', data: []),
      ),
    );

    await _pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('adminUsersEmpty')), findsOneWidget);
    expect(find.textContaining('Chưa có tài khoản'), findsOneWidget);
  });

  testWidgets('shows filtered empty state', (tester) async {
    _registerRepo(
      _FakeRepo(
        listResponder: () async =>
            const ApiResponse(success: true, message: 'OK', data: [_admin]),
      ),
    );

    await _pumpScreen(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('adminUserStatusFilterPending')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('adminUsersFilteredEmpty')), findsOneWidget);
  });

  testWidgets('shows error with retry, then recovers', (tester) async {
    var calls = 0;
    _registerRepo(
      _FakeRepo(
        listResponder: () async {
          calls++;
          if (calls == 1) {
            return const ApiResponse(success: false, message: 'Mất kết nối');
          }
          return const ApiResponse(
            success: true,
            message: 'OK',
            data: [_admin],
          );
        },
      ),
    );

    await _pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('adminUsersError')), findsOneWidget);
    expect(find.text('Mất kết nối'), findsOneWidget);

    await tester.tap(find.byKey(const Key('adminUsersRetryButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('adminUsersError')), findsNothing);
    expect(find.byKey(const Key('adminUsersList')), findsOneWidget);
  });
}
