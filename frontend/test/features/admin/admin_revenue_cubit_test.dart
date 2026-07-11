import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/features/admin/domain/admin_revenue.dart';
import 'package:marinelink/features/admin/domain/admin_revenue_repository.dart';
import 'package:marinelink/features/admin/presentation/cubit/admin_revenue_cubit.dart';

class _RecordingRepo implements AdminRevenueRepository {
  final Future<ApiResponse<RevenueReport>> Function(DateTime from, DateTime to)
  responder;
  final List<({DateTime from, DateTime to})> calls = [];

  _RecordingRepo(this.responder);

  @override
  Future<ApiResponse<RevenueReport>> getRevenue({
    required DateTime from,
    required DateTime to,
  }) {
    calls.add((from: from, to: to));
    return responder(from, to);
  }
}

RevenueReport _report({num total = 1000000}) {
  return RevenueReport(
    from: DateTime(2026, 6, 1),
    to: DateTime(2026, 6, 30),
    totalRevenue: total,
    dailySeries: [
      DailyRevenuePoint(date: DateTime(2026, 6, 1), revenue: total),
    ],
    topProducts: const [
      TopProduct(
        productId: 'p1',
        productName: 'Mực khô',
        quantitySold: 10,
        revenue: 500000,
      ),
    ],
  );
}

ApiResponse<RevenueReport> _ok([num total = 1000000]) =>
    ApiResponse(success: true, message: 'OK', data: _report(total: total));

void main() {
  // Fixed "now" so month arithmetic is deterministic.
  final now = DateTime(2026, 7, 15, 10);

  test('load() defaults to the current month range', () async {
    final repo = _RecordingRepo((_, _) async => _ok());
    final cubit = AdminRevenueCubit(repository: repo, now: now);

    await cubit.load();

    expect(repo.calls, hasLength(1));
    expect(repo.calls.first.from, DateTime(2026, 7, 1));
    expect(repo.calls.first.to, DateTime(2026, 7, 31));
    expect(cubit.state.status, AdminRevenueStatus.success);
    expect(cubit.state.selectedMonth, DateTime(2026, 7, 1));
    expect(cubit.state.customRange, isFalse);
  });

  test('selectMonth reloads with that month first/last day', () async {
    final repo = _RecordingRepo((_, _) async => _ok());
    final cubit = AdminRevenueCubit(repository: repo, now: now);

    await cubit.load();
    await cubit.selectMonth(DateTime(2026, 2, 1));

    expect(repo.calls, hasLength(2));
    expect(repo.calls.last.from, DateTime(2026, 2, 1));
    expect(repo.calls.last.to, DateTime(2026, 2, 28));
  });

  test('selectRange reloads with a custom day range and flags customRange',
      () async {
    final repo = _RecordingRepo((_, _) async => _ok());
    final cubit = AdminRevenueCubit(repository: repo, now: now);

    await cubit.selectRange(DateTime(2026, 6, 10), DateTime(2026, 6, 20));

    expect(repo.calls.last.from, DateTime(2026, 6, 10));
    expect(repo.calls.last.to, DateTime(2026, 6, 20));
    expect(cubit.state.customRange, isTrue);
  });

  test('selectRange swaps an inverted range', () async {
    final repo = _RecordingRepo((_, _) async => _ok());
    final cubit = AdminRevenueCubit(repository: repo, now: now);

    await cubit.selectRange(DateTime(2026, 6, 20), DateTime(2026, 6, 10));

    expect(repo.calls.last.from, DateTime(2026, 6, 10));
    expect(repo.calls.last.to, DateTime(2026, 6, 20));
  });

  test('earliestMonth is 24 months back from current month', () {
    final repo = _RecordingRepo((_, _) async => _ok());
    final cubit = AdminRevenueCubit(repository: repo, now: now);

    // Current month is 2026-07; 24 months window → earliest 2024-08.
    expect(cubit.earliestMonth, DateTime(2024, 8, 1));
  });

  test('emits failure when repository reports an error', () async {
    final repo = _RecordingRepo(
      (_, _) async => const ApiResponse(success: false, message: 'Server lỗi'),
    );
    final cubit = AdminRevenueCubit(repository: repo, now: now);

    await cubit.load();

    expect(cubit.state.status, AdminRevenueStatus.failure);
    expect(cubit.state.errorMessage, 'Server lỗi');
  });
}
