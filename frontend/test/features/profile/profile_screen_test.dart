import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marinelink/app/router/app_router.dart';
import 'package:marinelink/app/theme/app_theme.dart';
import 'package:marinelink/features/profile/presentation/screens/profile_screen.dart';
import 'package:marinelink/shared/navigation/buyer_navigation.dart';

import 'package:marinelink/app/di/service_locator.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/features/auth/domain/user.dart';
import 'package:marinelink/features/profile/domain/profile_repository.dart';
import 'package:marinelink/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockProfileRepository mockRepository;

  setUp(() {
    BuyerNavigation.resetForTesting();
    sl.allowReassignment = true;
    mockRepository = MockProfileRepository();

    const tUser = User(
      id: '1',
      fullName: 'Test User',
      email: 'test@example.com',
      phone: '0123456789',
      status: 'ACTIVE',
      roles: ['USER'],
    );

    when(() => mockRepository.getProfile()).thenAnswer(
      (_) async => const ApiResponse(success: true, message: 'OK', data: tUser),
    );

    sl.registerSingleton<ProfileRepository>(mockRepository);
    sl.registerFactory<ProfileCubit>(
      () => ProfileCubit(profileRepository: sl<ProfileRepository>()),
    );
  });

  tearDown(() {
    BuyerNavigation.resetForTesting();
    sl.reset();
  });

  testWidgets('opens orders from the profile page', (tester) async {
    // Set a larger viewport to ensure all items are rendered and visible
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final router = GoRouter(
      initialLocation: AppRoutes.profile,
      routes: [
        GoRoute(
          path: AppRoutes.profile,
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: AppRoutes.orders,
          builder: (context, state) =>
              const Scaffold(body: Text('Orders route probe')),
        ),
        GoRoute(
          path: AppRoutes.chat,
          builder: (context, state) =>
              const Scaffold(body: Text('Chat route probe')),
        ),
        GoRoute(
          path: AppRoutes.cart,
          builder: (context, state) =>
              const Scaffold(body: Text('Cart route probe')),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) =>
              const Scaffold(body: Text('Home route probe')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    );

    await tester.pumpAndSettle();

    expect(find.text('Tài khoản'), findsWidgets);
    expect(find.text('Đơn hàng của tôi'), findsOneWidget);

    await tester.tap(find.text('Đơn hàng của tôi'));
    await tester.pumpAndSettle();

    expect(find.text('Orders route probe'), findsOneWidget);
  });
}
