import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marinelink/core/constants/app_strings.dart';

import '../../../../core/errors/user_facing_error.dart';
import '../../domain/admin_revenue.dart';
import '../../domain/admin_revenue_repository.dart';

part 'admin_revenue_state.dart';

class AdminRevenueCubit extends Cubit<AdminRevenueState> {
  final AdminRevenueRepository repository;

  /// How far back the operator may look (2 years / 24 months).
  static const int maxMonthsBack = 24;

  AdminRevenueCubit({required this.repository, DateTime? now})
    : _now = now ?? DateTime.now(),
      super(const AdminRevenueState());

  final DateTime _now;

  /// First day of the current month (VN device clock).
  DateTime get currentMonth => DateTime(_now.year, _now.month, 1);

  /// Oldest month the selector may reach.
  DateTime get earliestMonth {
    final month = DateTime(_now.year, _now.month - (maxMonthsBack - 1), 1);
    return DateTime(month.year, month.month, 1);
  }

  /// Today (date-only) — the latest day any range may include.
  DateTime get today => DateTime(_now.year, _now.month, _now.day);

  /// Loads the current month by default.
  Future<void> load() => selectMonth(currentMonth);

  /// Loads the whole [month] (1st → last day).
  Future<void> selectMonth(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    return _fetch(
      from: first,
      to: last,
      selectedMonth: first,
      customRange: false,
    );
  }

  /// Loads a custom day range [from, to] (inclusive).
  Future<void> selectRange(DateTime from, DateTime to) {
    final normFrom = DateTime(from.year, from.month, from.day);
    final normTo = DateTime(to.year, to.month, to.day);
    final ordered = normFrom.isAfter(normTo);
    return _fetch(
      from: ordered ? normTo : normFrom,
      to: ordered ? normFrom : normTo,
      selectedMonth: state.selectedMonth ?? currentMonth,
      customRange: true,
    );
  }

  Future<void> _fetch({
    required DateTime from,
    required DateTime to,
    required DateTime selectedMonth,
    required bool customRange,
  }) async {
    emit(
      state.copyWith(
        status: AdminRevenueStatus.loading,
        selectedMonth: selectedMonth,
        rangeFrom: from,
        rangeTo: to,
        customRange: customRange,
      ),
    );
    try {
      final response = await repository.getRevenue(from: from, to: to);
      if (response.success && response.data != null) {
        emit(
          state.copyWith(
            status: AdminRevenueStatus.success,
            report: response.data,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: AdminRevenueStatus.failure,
            errorMessage: userFacingResponseMessage(
              response.message,
              fallback: AppStrings.adminRevenueLoadFailed,
            ),
          ),
        );
      }
    } catch (error) {
      emit(
        state.copyWith(
          status: AdminRevenueStatus.failure,
          errorMessage: userFacingErrorMessage(
            error,
            fallback: AppStrings.adminRevenueLoadUnexpected,
          ),
        ),
      );
    }
  }
}
