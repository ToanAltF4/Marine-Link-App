import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marinelink/app/di/service_locator.dart';
import 'package:marinelink/app/router/app_router.dart';
import 'package:marinelink/app/theme/app_theme.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/features/auth/domain/user.dart';
import 'package:marinelink/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:marinelink/features/auth/presentation/bloc/auth_event.dart';
import 'package:marinelink/features/auth/presentation/bloc/auth_state.dart';
import 'package:marinelink/features/profile/domain/profile.dart';
import 'package:marinelink/features/profile/domain/profile_repository.dart';
import 'package:marinelink/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:marinelink/features/profile/presentation/screens/profile_screen.dart';
import 'package:marinelink/shared/navigation/buyer_navigation.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockAuthBloc extends Mock implements AuthBloc {
  @override
  Future<void> close() async {}
}

void main() {
  setUpAll(() {
    registerFallbackValue(const AuthLogoutRequested());
  });

  late MockProfileRepository mockRepository;
  late MockAuthBloc mockAuthBloc;

  const tProfile = Profile(
    id: '1',
    fullName: 'Đại lý Test',
    email: 'test@example.com',
    phone: '0912345678',
    status: 'ACTIVE',
    roles: ['USER'],
    businessAddress: 'Cần Thơ',
    avatarUrl: 'https://example.com/avatar.png',
  );

  const tUser = User(
    id: '1',
    fullName: 'Đại lý Test',
    email: 'test@example.com',
    phone: '0912345678',
    status: 'ACTIVE',
    roles: ['USER'],
  );

  setUp(() {
    BuyerNavigation.resetForTesting();
    sl.allowReassignment = true;
    mockRepository = MockProfileRepository();
    mockAuthBloc = MockAuthBloc();

    when(() => mockRepository.getProfile()).thenAnswer(
      (_) async =>
          const ApiResponse(success: true, message: 'OK', data: tProfile),
    );
    when(
      () => mockAuthBloc.state,
    ).thenReturn(const AuthAuthenticated(user: tUser, token: 'token'));
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

    sl.registerSingleton<ProfileRepository>(mockRepository);
    sl.registerFactory<ProfileCubit>(
      () => ProfileCubit(profileRepository: sl<ProfileRepository>()),
    );
  });

  tearDown(() {
    BuyerNavigation.resetForTesting();
    sl.reset();
  });

  testWidgets('renders profile data with edit controls', (tester) async {
    await _pumpProfile(tester, mockAuthBloc);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profileScreen')), findsOneWidget);
    expect(find.byKey(const Key('profileFullNameText')), findsOneWidget);
    expect(find.text('test@example.com'), findsOneWidget);
    expect(find.byKey(const Key('profileEditButton')), findsOneWidget);
    expect(find.byKey(const Key('profileOrdersTile')), findsOneWidget);
  });

  testWidgets('validates phone before updateProfile', (tester) async {
    await _pumpProfile(tester, mockAuthBloc);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('profileEditButton')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('profilePhoneField')), '123');
    await tester.ensureVisible(find.byKey(const Key('profileSaveButton')));
    await tester.tap(find.byKey(const Key('profileSaveButton')));
    await tester.pumpAndSettle();

    expect(find.text('Số điện thoại không hợp lệ'), findsOneWidget);
    verifyNever(
      () => mockRepository.updateProfile(
        fullName: any(named: 'fullName'),
        phone: any(named: 'phone'),
        businessAddress: any(named: 'businessAddress'),
        avatarUrl: any(named: 'avatarUrl'),
      ),
    );
  });

  testWidgets('saves profile with avatarUrl', (tester) async {
    const updated = Profile(
      id: '1',
      fullName: 'Đại lý Mới',
      email: 'test@example.com',
      phone: '0987654321',
      status: 'ACTIVE',
      roles: ['USER'],
      businessAddress: 'Sóc Trăng',
      avatarUrl: 'https://example.com/new-avatar.png',
    );
    when(
      () => mockRepository.updateProfile(
        fullName: any(named: 'fullName'),
        phone: any(named: 'phone'),
        businessAddress: any(named: 'businessAddress'),
        avatarUrl: any(named: 'avatarUrl'),
      ),
    ).thenAnswer(
      (_) async =>
          const ApiResponse(success: true, message: 'OK', data: updated),
    );

    await _pumpProfile(tester, mockAuthBloc);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('profileEditButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('profileNameField')),
      'Đại lý Mới',
    );
    await tester.enterText(
      find.byKey(const Key('profilePhoneField')),
      '0987654321',
    );
    await tester.enterText(
      find.byKey(const Key('profileAddressField')),
      'Sóc Trăng',
    );
    await tester.enterText(
      find.byKey(const Key('profileAvatarUrlField')),
      'https://example.com/new-avatar.png',
    );
    await tester.ensureVisible(find.byKey(const Key('profileSaveButton')));
    await tester.tap(find.byKey(const Key('profileSaveButton')));
    await tester.pumpAndSettle();

    expect(find.text('Cập nhật hồ sơ thành công'), findsOneWidget);
    verify(
      () => mockRepository.updateProfile(
        fullName: 'Đại lý Mới',
        phone: '0987654321',
        businessAddress: 'Sóc Trăng',
        avatarUrl: 'https://example.com/new-avatar.png',
      ),
    ).called(1);
  });

  testWidgets('shows error and retries loadProfile', (tester) async {
    when(() => mockRepository.getProfile()).thenAnswer(
      (_) async =>
          const ApiResponse(success: false, message: 'Không tải được hồ sơ.'),
    );

    await _pumpProfile(tester, mockAuthBloc);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profileError')), findsOneWidget);
    expect(find.text('Không tải được hồ sơ.'), findsOneWidget);

    when(() => mockRepository.getProfile()).thenAnswer(
      (_) async =>
          const ApiResponse(success: true, message: 'OK', data: tProfile),
    );
    await tester.tap(find.byKey(const Key('appErrorStateRetryButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profileFullNameText')), findsOneWidget);
    verify(() => mockRepository.getProfile()).called(2);
  });

  testWidgets('opens orders from the profile page', (tester) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await _pumpProfile(tester, mockAuthBloc);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('profileOrdersTile')));
    await tester.pumpAndSettle();

    expect(find.text('Orders route probe'), findsOneWidget);
  });

  testWidgets('shows logout confirmation dialog and handles confirm',
      (tester) async {
    await _pumpProfile(tester, mockAuthBloc);
    await tester.pumpAndSettle();

    // Scroll to find logout tile if needed
    await tester.drag(
      find.byKey(const Key('profileScrollView')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('profileLogoutTile')));
    await tester.pumpAndSettle();

    // Verify dialog content
    expect(find.text('Đăng xuất?'), findsOneWidget);
    expect(
      find.text('Bạn có chắc chắn muốn đăng xuất khỏi MarineLink?'),
      findsOneWidget,
    );

    // Verify buttons
    expect(find.byKey(const Key('profileLogoutCancelButton')), findsOneWidget);
    expect(find.byKey(const Key('profileLogoutConfirmButton')), findsOneWidget);

    // Tap confirm
    await tester.tap(find.byKey(const Key('profileLogoutConfirmButton')));
    await tester.pumpAndSettle();

    // Verify navigation and auth event
    verify(() => mockAuthBloc.add(any())).called(1);
    expect(find.text('Login route probe'), findsOneWidget);
  });
}

Future<void> _pumpProfile(WidgetTester tester, AuthBloc authBloc) async {
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
        path: AppRoutes.changePassword,
        builder: (context, state) =>
            const Scaffold(body: Text('Change password route probe')),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) =>
            const Scaffold(body: Text('Login route probe')),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) =>
            const Scaffold(body: Text('Home route probe')),
      ),
      GoRoute(
        path: AppRoutes.cart,
        builder: (context, state) =>
            const Scaffold(body: Text('Cart route probe')),
      ),
      GoRoute(
        path: AppRoutes.productList,
        builder: (context, state) =>
            const Scaffold(body: Text('Products route probe')),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    MaterialApp.router(
      theme: AppTheme.light(),
      routerConfig: router,
      builder: (context, child) =>
          BlocProvider<AuthBloc>.value(value: authBloc, child: child!),
    ),
  );
}
