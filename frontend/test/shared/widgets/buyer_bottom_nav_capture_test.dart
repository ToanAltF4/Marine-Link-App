import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/app/theme/app_theme.dart';
import 'package:marinelink/shared/widgets/buyer_bottom_nav.dart';

void main() {
  testWidgets('captures buyer bottom nav preview', (tester) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final boundaryKey = GlobalKey();
    debugPrint('capture:start');

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: ColoredBox(
          color: const Color(0xFF1B202C),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: RepaintBoundary(
              key: boundaryKey,
              child: const SizedBox(
                width: 390,
                child: BuyerBottomNav(currentTab: BuyerBottomNavTab.cart),
              ),
            ),
          ),
        ),
      ),
    );
    debugPrint('capture:pumped-widget');

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    debugPrint('capture:after-pump');

    final boundary =
        boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    debugPrint('capture:got-boundary');
    final image = await boundary.toImage(pixelRatio: 3);
    debugPrint('capture:got-image');
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    debugPrint('capture:got-bytes');

    final output = File('build/test-artifacts/buyer_bottom_nav_capture.png');
    await output.parent.create(recursive: true);
    await output.writeAsBytes(bytes);
    debugPrint('capture:done');
  }, skip: true);
}
