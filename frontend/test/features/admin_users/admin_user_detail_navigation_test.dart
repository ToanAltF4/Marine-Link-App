import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marinelink/app/di/service_locator.dart';
import 'package:marinelink/app/router/app_router.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/features/admin_users/domain/admin_user.dart';
import 'package:marinelink/features/admin_users/domain/admin_user_repository.dart';
import 'package:marinelink/features/admin_users/presentation/cubit/admin_user_cubit.dart';
import 'package:marinelink/features/admin_users/presentation/screens/admin_user_detail_screen.dart';
import 'package:marinelink/features/admin_users/presentation/screens/admin_user_management_screen.dart';

class _FakeRepo implements AdminUserRepository {
  @override
  Future<ApiResponse<List<AdminUser>>> getUsers() async =>
      const ApiResponse(success: true, message: 'OK', data: [_dealer]);

  @override
  Future<ApiResponse<AdminUser>> approveUser(String id) async =>
      const ApiResponse(success: true, message: 'OK', data: _dealer);

  @override
  Future<ApiResponse<AdminUser>> lockUser(String id) async =>
      const ApiResponse(success: true, message: 'OK', data: _dealer);

  @override
  Future<ApiResponse<AdminUser>> unlockUser(String id) async =>
      const ApiResponse(success: true, message: 'OK', data: _dealer);
}

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

void main() {
  setUp(() async {
    await sl.reset();
    sl.registerFactory<AdminUserCubit>(
      () => AdminUserCubit(repository: _FakeRepo()),
    );
  });
  tearDown(() async => sl.reset());

  testWidgets('tapping a user card opens the detail screen with full info', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1600);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final router = GoRouter(
      initialLocation: AppRoutes.adminUsers,
      routes: [
        GoRoute(
          path: AppRoutes.adminUsers,
          builder: (context, state) => const AdminUserManagementScreen(),
        ),
        GoRoute(
          path: AppRoutes.adminUserDetail,
          builder: (context, state) =>
              AdminUserDetailScreen(user: state.extra as AdminUser?),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('adminUserCardTap_user-dealer-001')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('adminUserCardTap_user-dealer-001')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('adminUserDetailScreen')), findsOneWidget);
    expect(find.text('0301234567'), findsOneWidget);
    expect(find.text('Cửa hàng Ngư cụ Nguyễn Văn A'), findsOneWidget);
  });
}
