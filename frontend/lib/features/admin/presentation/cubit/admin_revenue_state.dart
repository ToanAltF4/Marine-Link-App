part of 'admin_revenue_cubit.dart';

enum AdminRevenueStatus { initial, loading, success, failure }

class AdminRevenueState extends Equatable {
  final AdminRevenueStatus status;
  final RevenueReport? report;

  /// First day of the month currently shown in the selector.
  final DateTime? selectedMonth;

  /// Active range being displayed (drives the day-range pickers).
  final DateTime? rangeFrom;
  final DateTime? rangeTo;

  /// True when the user filtered by a custom day range rather than a month.
  final bool customRange;

  final String? errorMessage;

  const AdminRevenueState({
    this.status = AdminRevenueStatus.initial,
    this.report,
    this.selectedMonth,
    this.rangeFrom,
    this.rangeTo,
    this.customRange = false,
    this.errorMessage,
  });

  AdminRevenueState copyWith({
    AdminRevenueStatus? status,
    RevenueReport? report,
    DateTime? selectedMonth,
    DateTime? rangeFrom,
    DateTime? rangeTo,
    bool? customRange,
    String? errorMessage,
  }) {
    return AdminRevenueState(
      status: status ?? this.status,
      report: report ?? this.report,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      rangeFrom: rangeFrom ?? this.rangeFrom,
      rangeTo: rangeTo ?? this.rangeTo,
      customRange: customRange ?? this.customRange,
      // errorMessage is intentionally not preserved: cleared on loading/success.
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    report,
    selectedMonth,
    rangeFrom,
    rangeTo,
    customRange,
    errorMessage,
  ];
}
