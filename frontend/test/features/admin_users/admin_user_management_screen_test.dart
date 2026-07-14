import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/app/di/service_locator.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/features/admin_users/data/admin_user_mock_repository.dart';
import 'package:marinelink/features/admin_users/domain/admin_user.dart';
import 'package:marinelink/features/admin_users/domain/admin_user_repository.dart';
import 'package:marinelink/features/admin_users/presentation/cubit/admin_user_cubit.dart';
import 'package:marinelink/features/admin_users/presentation/screens/admin_user_management_screen.dart';

class _FakeRepo implements AdminUserRepository {
  final Future<ApiResponse<List<AdminUser>>> Function() listResponder;
  final Future<ApiResponse<AdminUser>> Function(String id) approveResponder;
  final Future<ApiResponse<AdminUser>> Function(Map<String, String> payload)
  createResponder;

  /// Payload của lần gọi createUser gần nhất (kiểm tra dữ liệu form gửi lên).
  Map<String, String>? lastCreatePayload;

  _FakeRepo({
    required this.listResponder,
    Future<ApiResponse<AdminUser>> Function(String id)? approveResponder,
    Future<ApiResponse<AdminUser>> Function(Map<String, String> payload)?
    createResponder,
  }) : approveResponder =
           approveResponder ??
           ((_) async =>
               const ApiResponse(success: false, message: 'Không duyệt được')),
       createResponder =
           createResponder ??
           ((_) async =>
               const ApiResponse(success: false, message: 'Không tạo được'));

  @override
  Future<ApiResponse<List<AdminUser>>> getUsers() => listResponder();

  @override
  Future<ApiResponse<AdminUser>> approveUser(String id) => approveResponder(id);

  @override
  Future<ApiResponse<AdminUser>> lockUser(String id) => approveResponder(id);

  @override
  Future<ApiResponse<AdminUser>> unlockUser(String id) => approveResponder(id);

  @override
  Future<ApiResponse<AdminUser>> createUser({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String roleCode = 'STAFF',
  }) {
    final payload = {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'password': password,
      'roleCode': roleCode,
    };
    lastCreatePayload = payload;
    return createResponder(payload);
  }
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

/// Mở form tạo tài khoản từ nút trên AppBar.
Future<void> _openCreateForm(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('adminCreateUserButton')));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('adminCreateUserForm')), findsOneWidget);
}

Future<void> _fillCreateForm(
  WidgetTester tester, {
  String fullName = 'Nhân viên Mới',
  String email = 'nhanvien@marinelink.demo',
  String phone = '0987654321',
  String password = 'matkhau123',
}) async {
  await tester.enterText(
    find.byKey(const Key('adminCreateUserFullNameField')),
    fullName,
  );
  await tester.enterText(
    find.byKey(const Key('adminCreateUserEmailField')),
    email,
  );
  await tester.enterText(
    find.byKey(const Key('adminCreateUserPhoneField')),
    phone,
  );
  await tester.enterText(
    find.byKey(const Key('adminCreateUserPasswordField')),
    password,
  );
  await tester.pump();
}

Future<void> _tapSubmit(WidgetTester tester) async {
  final submit = find.byKey(const Key('adminCreateUserSubmitButton'));
  await tester.ensureVisible(submit);
  await tester.pump();
  await tester.tap(submit);
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

  testWidgets('create user form validates required fields', (tester) async {
    final repo = _FakeRepo(
      listResponder: () async =>
          const ApiResponse(success: true, message: 'OK', data: [_admin]),
    );
    _registerRepo(repo);

    await _pumpScreen(tester);
    await tester.pumpAndSettle();
    await _openCreateForm(tester);

    await _tapSubmit(tester);
    await tester.pumpAndSettle();

    // Không gọi backend khi form chưa hợp lệ.
    expect(repo.lastCreatePayload, isNull);
    expect(
      find.text('Vui lòng kiểm tra lại thông tin đã nhập.'),
      findsOneWidget,
    );
    expect(find.text('Email không được để trống'), findsOneWidget);
    expect(find.text('Số điện thoại không được để trống'), findsOneWidget);
    expect(find.text('Mật khẩu không được để trống'), findsOneWidget);
    expect(find.byKey(const Key('adminCreateUserForm')), findsOneWidget);
  });

  testWidgets('creates a staff account and shows the success snack bar', (
    tester,
  ) async {
    _registerRepo(AdminUserMockRepository(initialUsers: const [_admin]));

    await _pumpScreen(tester);
    await tester.pumpAndSettle();
    await _openCreateForm(tester);
    await _fillCreateForm(tester);

    await _tapSubmit(tester);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('adminCreateUserSuccessSnackBar')),
      findsOneWidget,
    );
    expect(find.text('Đã tạo tài khoản.'), findsOneWidget);
    // Form đã đóng, tài khoản mới xuất hiện trong danh sách.
    expect(find.byKey(const Key('adminCreateUserForm')), findsNothing);
    expect(find.text('Nhân viên Mới'), findsOneWidget);
    expect(find.text('nhanvien@marinelink.demo'), findsOneWidget);
  });

  testWidgets('sends the selected role code to the repository', (tester) async {
    final repo = _FakeRepo(
      listResponder: () async =>
          const ApiResponse(success: true, message: 'OK', data: [_admin]),
      createResponder: (_) async =>
          const ApiResponse(success: true, message: 'OK', data: _staff),
    );
    _registerRepo(repo);

    await _pumpScreen(tester);
    await tester.pumpAndSettle();
    await _openCreateForm(tester);
    await _fillCreateForm(tester);

    await tester.tap(find.byKey(const Key('adminCreateUserRoleDropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quản trị (ADMIN)').last);
    await tester.pumpAndSettle();

    await _tapSubmit(tester);
    await tester.pumpAndSettle();

    expect(repo.lastCreatePayload, {
      'fullName': 'Nhân viên Mới',
      'email': 'nhanvien@marinelink.demo',
      'phone': '0987654321',
      'password': 'matkhau123',
      'roleCode': 'ADMIN',
    });
  });

  testWidgets('shows the backend error message when creation fails', (
    tester,
  ) async {
    _registerRepo(
      _FakeRepo(
        listResponder: () async =>
            const ApiResponse(success: true, message: 'OK', data: [_admin]),
        createResponder: (_) async =>
            const ApiResponse(success: false, message: 'Email đã tồn tại'),
      ),
    );

    await _pumpScreen(tester);
    await tester.pumpAndSettle();
    await _openCreateForm(tester);
    await _fillCreateForm(tester);

    await _tapSubmit(tester);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('adminCreateUserErrorSnackBar')),
      findsOneWidget,
    );
    expect(find.text('Email đã tồn tại'), findsOneWidget);
    // Form vẫn mở để người dùng sửa lại thông tin.
    expect(find.byKey(const Key('adminCreateUserForm')), findsOneWidget);
  });

  testWidgets('disables the submit button while the request is in flight', (
    tester,
  ) async {
    final completer = Completer<ApiResponse<AdminUser>>();
    _registerRepo(
      _FakeRepo(
        listResponder: () async =>
            const ApiResponse(success: true, message: 'OK', data: [_admin]),
        createResponder: (_) => completer.future,
      ),
    );

    await _pumpScreen(tester);
    await tester.pumpAndSettle();
    await _openCreateForm(tester);
    await _fillCreateForm(tester);

    await _tapSubmit(tester);
    await tester.pump();

    expect(
      find.byKey(const Key('adminCreateUserSubmitProgress')),
      findsOneWidget,
    );
    final button = tester.widget<FilledButton>(
      find.byKey(const Key('adminCreateUserSubmitButton')),
    );
    expect(button.onPressed, isNull);

    // Bấm lại khi đang gửi không tạo thêm request nào.
    await tester.tap(
      find.byKey(const Key('adminCreateUserSubmitButton')),
      warnIfMissed: false,
    );
    await tester.pump();

    completer.complete(
      const ApiResponse(success: true, message: 'OK', data: _staff),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('adminCreateUserSuccessSnackBar')),
      findsOneWidget,
    );
  });
}
