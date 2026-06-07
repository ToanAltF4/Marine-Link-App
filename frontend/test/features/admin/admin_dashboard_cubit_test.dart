import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/features/admin/domain/admin_dashboard.dart';
import 'package:marinelink/features/admin/domain/admin_dashboard_repository.dart';
import 'package:marinelink/features/admin/presentation/cubit/admin_dashboard_cubit.dart';

class _FakeRepo implements AdminDashboardRepository {
  final Future<ApiResponse<AdminDashboard>> Function() responder;
  _FakeRepo(this.responder);

  @override
  Future<ApiResponse<AdminDashboard>> getDashboard() => responder();
}

const _dashboard = AdminDashboard(
  pendingOrders: 3,
  monthlyRevenue: 1000,
  newComplaints: 1,
  activeUsers: 4,
  lowStockProducts: 2,
);

void main() {
  blocTest<AdminDashboardCubit, AdminDashboardState>(
    'emits [loading, success] when repository returns data',
    build: () => AdminDashboardCubit(
      repository: _FakeRepo(
        () async => const ApiResponse(
          success: true,
          message: 'OK',
          data: _dashboard,
        ),
      ),
    ),
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<AdminDashboardState>().having(
        (s) => s.status,
        'status',
        AdminDashboardStatus.loading,
      ),
      isA<AdminDashboardState>()
          .having((s) => s.status, 'status', AdminDashboardStatus.success)
          .having((s) => s.dashboard, 'dashboard', _dashboard),
    ],
  );

  blocTest<AdminDashboardCubit, AdminDashboardState>(
    'emits [loading, failure] when repository reports failure',
    build: () => AdminDashboardCubit(
      repository: _FakeRepo(
        () async => const ApiResponse(success: false, message: 'Server lỗi'),
      ),
    ),
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<AdminDashboardState>().having(
        (s) => s.status,
        'status',
        AdminDashboardStatus.loading,
      ),
      isA<AdminDashboardState>()
          .having((s) => s.status, 'status', AdminDashboardStatus.failure)
          .having((s) => s.errorMessage, 'errorMessage', 'Server lỗi'),
    ],
  );

  blocTest<AdminDashboardCubit, AdminDashboardState>(
    'emits [loading, failure] when repository throws',
    build: () => AdminDashboardCubit(
      repository: _FakeRepo(() async => throw Exception('boom')),
    ),
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<AdminDashboardState>().having(
        (s) => s.status,
        'status',
        AdminDashboardStatus.loading,
      ),
      isA<AdminDashboardState>().having(
        (s) => s.status,
        'status',
        AdminDashboardStatus.failure,
      ),
    ],
  );
}
