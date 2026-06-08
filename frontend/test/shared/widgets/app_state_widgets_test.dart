import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/app/theme/app_theme.dart';
import 'package:marinelink/shared/widgets/app_empty_state.dart';
import 'package:marinelink/shared/widgets/app_error_state.dart';
import 'package:marinelink/shared/widgets/app_loading_indicator.dart';

Future<void> _pumpStateWidget(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(360, 640),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: child),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('AppEmptyState renders responsive message and action', (
    tester,
  ) async {
    var tapped = false;

    await _pumpStateWidget(
      tester,
      AppEmptyState(
        key: const Key('emptyStateHost'),
        message: 'Chưa có dữ liệu phù hợp',
        actionLabel: 'Tải lại',
        onAction: () => tapped = true,
        icon: Icons.search_off_outlined,
      ),
      size: const Size(320, 360),
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('emptyStateHost')), findsOneWidget);
    expect(find.byKey(const Key('appEmptyStateIcon')), findsOneWidget);
    expect(find.byKey(const Key('appEmptyStateMessage')), findsOneWidget);
    expect(find.text('Chưa có dữ liệu phù hợp'), findsOneWidget);

    await tester.tap(find.byKey(const Key('appEmptyStateActionButton')));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('AppErrorState renders retry action with default label', (
    tester,
  ) async {
    var retryCount = 0;

    await _pumpStateWidget(
      tester,
      AppErrorState(
        message: 'Không tải được dữ liệu. Vui lòng thử lại.',
        onRetry: () => retryCount += 1,
      ),
      size: const Size(320, 360),
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('appErrorStateIcon')), findsOneWidget);
    expect(find.byKey(const Key('appErrorStateMessage')), findsOneWidget);
    expect(
      find.text('Không tải được dữ liệu. Vui lòng thử lại.'),
      findsOneWidget,
    );
    expect(find.text('Thử lại'), findsOneWidget);

    await tester.tap(find.byKey(const Key('appErrorStateRetryButton')));
    await tester.pump();

    expect(retryCount, 1);
  });

  testWidgets('AppLoadingIndicator keeps spinner and message centered', (
    tester,
  ) async {
    await _pumpStateWidget(
      tester,
      const AppLoadingIndicator(message: 'Đang tải dữ liệu'),
      size: const Size(320, 280),
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('appLoadingIndicatorSpinner')), findsOneWidget);
    expect(find.byKey(const Key('appLoadingIndicatorMessage')), findsOneWidget);
    expect(find.text('Đang tải dữ liệu'), findsOneWidget);
  });
}
