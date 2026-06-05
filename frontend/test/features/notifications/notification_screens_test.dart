import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/app/theme/app_theme.dart';
import 'package:marinelink/features/notifications/presentation/screens/notifications_screen.dart';

void main() {
  group('NotificationsScreen', () {
    testWidgets('renders the notifications list with mock data', (tester) async {
      // Set a larger viewport to ensure all items are rendered and visible
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const NotificationsScreen(),
        ),
      );

      // Wait for loading indicator to disappear and mock data to load
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('Thông báo'), findsOneWidget);
      
      // Check for unread count in summary card
      expect(find.text('Chưa đọc'), findsOneWidget);
      expect(find.text('2'), findsWidgets); // Might find multiple if count appears in multiple places

      // Check for specific notification titles from mock repository
      expect(find.textContaining('Đơn hàng #OD2305'), findsOneWidget);
      expect(find.textContaining('Giá tôm khô'), findsOneWidget);
      
      // Ensure we can find items in the "Earlier" section
      await tester.scrollUntilVisible(find.textContaining('Nhân viên hỗ trợ'), 500);
      expect(find.textContaining('Nhân viên hỗ trợ'), findsOneWidget);

      // Verify the back button exists
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    });

    testWidgets('marking a notification as read updates the UI', (tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const NotificationsScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      // Initially 2 unread
      expect(find.text('2'), findsWidgets);

      // Tap on the first unread notification
      await tester.tap(find.textContaining('Đơn hàng #OD2305'));
      
      // Wait for repository call and state update
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Now should have 1 unread
      expect(find.text('1'), findsWidgets);
    });
  });
}
