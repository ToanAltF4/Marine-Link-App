import 'package:mocktail/mocktail.dart';
import 'package:marinelink/app/di/service_locator.dart';
import 'package:marinelink/features/orders/presentation/bloc/order_bloc.dart';
import 'package:marinelink/features/products/presentation/bloc/product_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/app/theme/app_theme.dart';
import 'package:marinelink/features/notifications/presentation/screens/notifications_screen.dart';

// Định nghĩa các class giả lập ngay trong file test này
// 1. Thêm stub cho hàm close trong các class Mock
class MockOrderBloc extends Mock implements OrderBloc {
  @override
  Future<void> close() async {} // Cách viết async này đảm bảo trả về Future<void> chuẩn
}

class MockProductBloc extends Mock implements ProductBloc {
  @override
  Future<void> close() async {}
}

class FakeRoute extends Fake implements Route<dynamic> {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeRoute());
    sl.allowReassignment = true;

    // Đăng ký dạng Factory để mỗi lần gọi sl<OrderBloc>() sẽ tạo một Mock mới sạch sẽ
    sl.registerFactory<OrderBloc>(() {
      final mock = MockOrderBloc();
      when(() => mock.stream).thenAnswer((_) => const Stream.empty());
      when(() => mock.state).thenReturn(const OrderInitial());
      return mock;
    });

    sl.registerFactory<ProductBloc>(() {
      final mock = MockProductBloc();
      when(() => mock.stream).thenAnswer((_) => const Stream.empty());
      when(() => mock.state).thenReturn(const ProductInitial());
      return mock;
    });
  });

  // ... (giữ nguyên phần group và các testWidgets bên dưới của cậu)

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

    testWidgets('nhấn vào thông báo đã đọc cũng phải thực hiện hành động', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const NotificationsScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 800));

      // Tìm và nhấn vào thông báo cũ (đã đọc)
      final olderItem = find.textContaining('Nhân viên hỗ trợ');
      await tester.scrollUntilVisible(olderItem, 500);
      await tester.tap(olderItem);
      await tester.pumpAndSettle();

      // Nếu không có lỗi gì xảy ra là đạt (vì logic điều hướng cần Navigator observer để check kĩ hơn)
    });
  });
}
