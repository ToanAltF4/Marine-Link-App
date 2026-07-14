part of 'admin_dashboard_cubit.dart';

enum AdminDashboardStatus { initial, loading, success, failure }

class AdminDashboardState extends Equatable {
  final AdminDashboardStatus status;
  final AdminDashboard? dashboard;
  final String? errorMessage;

  const AdminDashboardState({
    this.status = AdminDashboardStatus.initial,
    this.dashboard,
    this.errorMessage,
  });

  AdminDashboardState copyWith({
    AdminDashboardStatus? status,
    AdminDashboard? dashboard,
    String? errorMessage,
  }) {
    return AdminDashboardState(
      status: status ?? this.status,
      dashboard: dashboard ?? this.dashboard,
      // errorMessage is intentionally not preserved: cleared on loading/success.
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, dashboard, errorMessage];
}
