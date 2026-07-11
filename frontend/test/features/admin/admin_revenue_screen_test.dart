import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/app/di/service_locator.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/features/admin/domain/admin_revenue.dart';
import 'package:marinelink/features/admin/domain/admin_revenue_repository.dart';
import 'package:marinelink/features/admin/presentation/cubit/admin_revenue_cubit.dart';
import 'package:marinelink/features/admin/presentation/screens/admin_revenue_screen.dart';

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

RevenueReport _report({
  num total = 5000000,
  List<DailyRevenuePoint>? daily,
  List<TopProduct>? top,
}) {
  return RevenueReport(
    from: DateTime(2026, 7, 1),
    to: DateTime(2026, 7, 31),
    totalRevenue: total,
    dailySeries:
        daily ??
        [
          DailyRevenuePoint(date: DateTime(2026, 7, 1), revenue: 2000000),
          DailyRevenuePoint(date: DateTime(2026, 7, 2), revenue: 3000000),
        ],
    topProducts:
        top ??
        const [
          TopProduct(
            productId: 'p1',
            productName: 'Mực khô loại 1',
            quantitySold: 42,
            revenue: 8400000,
          ),
        ],
  );
}

final _now = DateTime(2026, 7, 15, 10);

void _registerRepo(AdminRevenueRepository repo) {
  sl.registerFactory<AdminRevenueCubit>(
    () => AdminRevenueCubit(repository: repo, now: _now),
  );
}

Future<void> _pump(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(900, 1800);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(const MaterialApp(home: AdminRevenueScreen()));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => sl.reset());
  tearDown(() => sl.reset());

  testWidgets('renders total, daily series and top products on success', (
    tester,
  ) async {
    _registerRepo(_RecordingRepo((_, _) async {
      return ApiResponse(success: true, message: 'OK', data: _report());
    }));

    await _pump(tester);

    expect(find.byKey(const Key('adminRevenueScreen')), findsOneWidget);
    expect(find.byKey(const Key('adminRevenueMonthSelector')), findsOneWidget);
    expect(find.byKey(const Key('adminRevenueTotal')), findsOneWidget);
    expect(find.byKey(const Key('adminRevenueDailyList')), findsOneWidget);
    expect(find.byKey(const Key('adminRevenueTopProducts')), findsOneWidget);
    expect(find.text('Mực khô loại 1'), findsOneWidget);
    expect(find.text('Tháng 7/2026'), findsOneWidget);
  });

  testWidgets('tapping the previous-month chevron reloads that month', (
    tester,
  ) async {
    final repo = _RecordingRepo((_, _) async {
      return ApiResponse(success: true, message: 'OK', data: _report());
    });
    _registerRepo(repo);

    await _pump(tester);
    expect(repo.calls, hasLength(1));
    expect(repo.calls.first.from, DateTime(2026, 7, 1));

    await tester.tap(find.byKey(const Key('adminRevenueMonthPrev')));
    await tester.pumpAndSettle();

    expect(repo.calls, hasLength(2));
    expect(repo.calls.last.from, DateTime(2026, 6, 1));
    expect(repo.calls.last.to, DateTime(2026, 6, 30));
    expect(find.text('Tháng 6/2026'), findsOneWidget);
  });

  testWidgets('shows empty placeholders when there are no sales', (
    tester,
  ) async {
    _registerRepo(_RecordingRepo((_, _) async {
      return ApiResponse(
        success: true,
        message: 'OK',
        data: _report(total: 0, daily: const [], top: const []),
      );
    }));

    await _pump(tester);

    expect(find.byKey(const Key('adminRevenueEmpty')), findsOneWidget);
    expect(find.byKey(const Key('adminRevenueDailyEmpty')), findsOneWidget);
    expect(find.byKey(const Key('adminRevenueTopEmpty')), findsOneWidget);
  });

  testWidgets('shows error with retry then recovers', (tester) async {
    var calls = 0;
    _registerRepo(_RecordingRepo((_, _) async {
      calls++;
      if (calls == 1) {
        return const ApiResponse(success: false, message: 'Mất kết nối');
      }
      return ApiResponse(success: true, message: 'OK', data: _report());
    }));

    await _pump(tester);

    expect(find.byKey(const Key('adminRevenueError')), findsOneWidget);
    expect(find.text('Mất kết nối'), findsOneWidget);

    await tester.tap(find.byKey(const Key('adminRevenueRetryButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('adminRevenueError')), findsNothing);
    expect(find.byKey(const Key('adminRevenueTotal')), findsOneWidget);
  });
}
