import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/app/theme/app_theme.dart';
import 'package:marinelink/shared/widgets/buyer_bottom_nav.dart';

void main() {
  testWidgets('keeps all bottom navigation labels on a single line', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 780);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          bottomNavigationBar: BuyerBottomNav(
            currentTab: BuyerBottomNavTab.cart,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    const labels = <String>[
      'Trang ch\u1ee7',
      'S\u1ea3n ph\u1ea9m',
      'Gi\u1ecf h\u00e0ng',
      'Chat',
      'T\u00e0i kho\u1ea3n',
    ];

    for (final label in labels) {
      final finder = find.text(label);
      expect(finder, findsOneWidget);

      final text = tester.widget<Text>(finder);
      expect(text.maxLines, 1);
      expect(text.softWrap, isFalse);
    }

    expect(find.textContaining('\n'), findsNothing);
  });
}
