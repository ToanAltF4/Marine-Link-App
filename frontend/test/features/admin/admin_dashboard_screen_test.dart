import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/app/di/service_locator.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/features/admin/domain/admin_dashboard.dart';
import 'package:marinelink/features/admin/domain/admin_dashboard_repository.dart';
import 'package:marinelink/features/admin/presentation/cubit/admin_dashboard_cubit.dart';
import 'package:marinelink/features/admin/presentation/screens/admin_dashboard_screen.dart';

class _FakeRepo implements AdminDashboardRepository {
  final Future<ApiResponse<AdminDashboard>> Function() responder;
  _FakeRepo(this.responder);

  @override
  Future<ApiResponse<AdminDashboard>> getDashboard() => responder();
}

AdminDashboard _dashboard({List<AdminRecentOrder>? recentOrders}) {
  return AdminDashboard(
    pendingOrders: 18,
    monthlyRevenue: 42850000,
    newComplaints: 2,
    activeUsers: 12,
    lowStockProducts: 5,
    recentOrders:
        recentOrders ??
        const [
          AdminRecentOrder(
            id: 'order-2901',
            orderCode: 'ML-2901',
            status: 'PENDING',
            totalAmount: 12400000,
          ),
        ],
  );
}

void _registerRepo(AdminDashboardRepository repo) {
  sl.registerFactory<AdminDashboardCubit>(
    () => AdminDashboardCubit(repository: repo),
  );
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  Size size = const Size(800, 1600),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(const MaterialApp(home: AdminDashboardScreen()));
}

void main() {
  setUp(() => sl.reset());
  tearDown(() => sl.reset());

  testWidgets('shows loading indicator while fetching', (tester) async {
    final completer = Completer<ApiResponse<AdminDashboard>>();
    _registerRepo(_FakeRepo(() => completer.future));

    await _pumpScreen(tester);
    await tester.pump();

    expect(find.byKey(const Key('adminDashboardLoading')), findsOneWidget);
    expect(find.byKey(const Key('adminSystemSummaryBand')), findsNothing);

    completer.complete(
      ApiResponse(success: true, message: 'OK', data: _dashboard()),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('adminDashboardLoading')), findsNothing);
  });

  testWidgets('renders metric cards and recent orders on success', (
    tester,
  ) async {
    _registerRepo(
      _FakeRepo(
        () async =>
            ApiResponse(success: true, message: 'OK', data: _dashboard()),
      ),
    );

    await _pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('adminSystemSummaryBand')), findsOneWidget);
    expect(find.byKey(const Key('adminMonthlyRevenueCard')), findsOneWidget);
    expect(find.byKey(const Key('adminPendingOrdersCard')), findsOneWidget);
    expect(find.byKey(const Key('adminLowStockCard')), findsOneWidget);
    expect(find.byKey(const Key('adminActiveUsersCard')), findsOneWidget);
    expect(find.byKey(const Key('adminRecentOrdersSection')), findsOneWidget);
    // Admin có lối tắt vào bản đồ kho hàng.
    expect(find.byKey(const Key('adminWarehousesShortcut')), findsOneWidget);

    expect(find.text('18 đơn'), findsOneWidget);
    expect(find.text('5 mã'), findsOneWidget);
    expect(find.text('12 đại lý'), findsOneWidget);
    expect(find.text('Doanh thu tháng này'), findsOneWidget);
    expect(find.text('ML-2901'), findsOneWidget);
    expect(find.text('Chờ duyệt'), findsOneWidget);
  });

  testWidgets('renders dashboard states at phone width without overflow', (
    tester,
  ) async {
    _registerRepo(
      _FakeRepo(
        () async =>
            ApiResponse(success: true, message: 'OK', data: _dashboard()),
      ),
    );

    await _pumpScreen(tester, size: const Size(390, 1000));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('adminDashboardScreen')), findsOneWidget);
    expect(find.byKey(const Key('adminSystemSummaryBand')), findsOneWidget);
    expect(find.byKey(const Key('adminOperationsSection')), findsOneWidget);
  });

  testWidgets('shows empty placeholder when there are no recent orders', (
    tester,
  ) async {
    _registerRepo(
      _FakeRepo(
        () async => ApiResponse(
          success: true,
          message: 'OK',
          data: _dashboard(recentOrders: const []),
        ),
      ),
    );

    await _pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('adminRecentOrdersEmpty')), findsOneWidget);
    expect(find.text('Chưa có đơn hàng gần đây.'), findsOneWidget);
  });

  testWidgets('shows error with retry, then recovers after retry', (
    tester,
  ) async {
    var calls = 0;
    _registerRepo(
      _FakeRepo(() async {
        calls++;
        if (calls == 1) {
          return const ApiResponse(success: false, message: 'Mất kết nối');
        }
        return ApiResponse(success: true, message: 'OK', data: _dashboard());
      }),
    );

    await _pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('adminDashboardError')), findsOneWidget);
    expect(find.text('Mất kết nối'), findsOneWidget);

    await tester.tap(find.byKey(const Key('adminDashboardRetryButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('adminDashboardError')), findsNothing);
    expect(find.byKey(const Key('adminSystemSummaryBand')), findsOneWidget);
  });
}
