import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets/app_assets.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/widgets/admin_role_guard.dart';
import '../../features/admin_products/presentation/screens/admin_product_management_screen.dart';
import '../../features/admin_users/presentation/screens/admin_user_management_screen.dart';
import '../../features/chat/data/chat_mock_repository.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/chat/presentation/screens/chat_rooms_list_screen.dart';
import '../../features/chat/presentation/screens/staff_chat_management_screen.dart';
import '../../features/auth/domain/user.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_verification_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/change_password_screen.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/checkout/presentation/screens/checkout_screen.dart';
import '../../features/checkout/presentation/screens/vnpay_result_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/orders/presentation/screens/order_detail_screen.dart';
import '../../features/orders/presentation/screens/order_list_screen.dart';
import '../../features/products/presentation/screens/product_detail_screen.dart';
import '../../features/products/presentation/screens/product_list_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/staff/presentation/screens/staff_dashboard_screen.dart';
import '../../features/staff/presentation/widgets/staff_role_guard.dart';
import '../../features/warehouse_map/presentation/screens/warehouse_map_screen.dart';
import '../../shared/navigation/app_back_exit_controller.dart';
import '../../shared/navigation/buyer_navigation.dart';
import '../../shared/widgets/app_back_exit_scope.dart';

abstract class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const verifyEmail = '/verify-email';
  static const changePassword = '/change-password';
  static const home = '/home';
  static const productList = '/products';
  static const productDetail = '/products/:id';
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const vnpayResult = '/payments/vnpay/result';
  static const vnpayResultAndroidAlias = '/vnpay/result';
  static const orders = '/orders';
  static const orderDetail = '/orders/:id';
  static const notifications = '/home/notifications';
  static const chat = '/chat';
  static const chatRoom = '/chat/:roomId';
  static const chatOrderRoom = '/chat/order/:orderId';
  static const profile = '/profile';
  static const warehouseMap = '/warehouses';

  static const staffDashboard = '/staff';
  static const staffOrders = '/staff/orders';
  static const staffNotifications = '/staff/notifications';
  static const staffChat = '/staff/chat';
  static const staffProducts = '/staff/products';
  static const staffProfile = '/staff/profile';
  static const staffWarehouses = '/staff/warehouses';
  static const adminDashboard = '/admin';
  static const adminProducts = '/admin/products';
  static const adminUsers = '/admin/users';
  static const adminOrders = '/admin/orders';
  static const adminNotifications = '/admin/notifications';
  static const adminProfile = '/admin/profile';

  static String productDetailPath(String id) => '$productList/$id';
  static String orderDetailPath(String id) => '$orders/$id';
  static String chatRoomPath(String roomId) => '$chat/$roomId';
  static String chatOrderRoomPath(String orderId) => '$chat/order/$orderId';
  static String staffOrderDetailPath(String id) => '$staffOrders/$id';
  static String staffChatRoomPath(String roomId) => '$staffChat/$roomId';
  static String adminOrderDetailPath(String id) => '$adminOrders/$id';

  static String productListLocation({String? query, String? categoryId}) {
    final params = <String, String>{};
    if (query != null && query.trim().isNotEmpty) {
      params['q'] = query.trim();
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      params['categoryId'] = categoryId;
    }
    return params.isEmpty
        ? productList
        : Uri(path: productList, queryParameters: params).toString();
  }
}

class AppRouter {
  AppRouter._();

  static final rootNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'rootNavigator',
  );

  static final GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    navigatorKey: rootNavigatorKey,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const _SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => AppBackExitScope(
          child: LoginScreen(
            onAuthenticated: (user) => _routeByRole(context, user),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => AppBackExitScope(
          onFirstBack: (context) => context.go(AppRoutes.login),
          child: const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return OtpVerificationScreen(email: email);
        },
      ),
      GoRoute(path: AppRoutes.vnpayResult, builder: _vnpayResultBuilder),
      GoRoute(
        path: AppRoutes.vnpayResultAndroidAlias,
        builder: _vnpayResultBuilder,
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _BuyerShellBackScope(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'notifications', // matches /home/notifications
                    builder: (context, state) => const NotificationsScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.productList,
                builder: (context, state) => ProductListScreen(
                  initialQuery: state.uri.queryParameters['q'],
                  initialCategoryId: state.uri.queryParameters['categoryId'],
                ),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => ProductDetailScreen(
                      productId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.cart,
                builder: (context, state) => const CartScreen(),
              ),
              GoRoute(
                path: AppRoutes.checkout,
                builder: (context, state) => const CheckoutScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.chat,
                builder: (context, state) => const ChatRoomsListScreen(),
                routes: [
                  GoRoute(
                    path: 'order/:orderId',
                    builder: (context, state) =>
                        ChatScreen(orderId: state.pathParameters['orderId']!),
                  ),
                  GoRoute(
                    path: ':roomId',
                    // Do NOT fall back to a mock room id here — in remote mode a
                    // mock UUID would hit GET /api/chat/{id} → 404. A null/empty
                    // id makes ChatScreen resolve the buyer's own room instead.
                    builder: (context, state) =>
                        ChatScreen(roomId: state.pathParameters['roomId']),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
              GoRoute(
                path: AppRoutes.orders,
                builder: (context, state) => const OrderListScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) =>
                        OrderDetailScreen(orderId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.warehouseMap,
        builder: (context, state) => const WarehouseMapScreen(),
      ),
      GoRoute(
        path: AppRoutes.staffDashboard,
        builder: (context, state) =>
            const StaffRoleGuard(child: StaffDashboardScreen()),
        routes: [
          GoRoute(
            path: 'orders',
            builder: (context, state) =>
                const StaffRoleGuard(child: OrderListScreen(staffMode: true)),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => StaffRoleGuard(
                  child: OrderDetailScreen(
                    orderId: state.pathParameters['id']!,
                    staffMode: true,
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'notifications',
            builder: (context, state) =>
                const StaffRoleGuard(child: NotificationsScreen()),
          ),
          GoRoute(
            path: 'chat',
            builder: (context, state) => const StaffRoleGuard(
              child: StaffChatManagementScreen(key: Key('staffChatScreen')),
            ),
            routes: [
              GoRoute(
                path: ':roomId',
                builder: (context, state) => StaffRoleGuard(
                  child: ChatScreen(
                    key: const Key('staffChatThreadScreen'),
                    roomId:
                        state.pathParameters['roomId'] ??
                        ChatMockRepository.defaultRoomId,
                    staffMode: true,
                    staffBackLocation: AppRoutes.staffChat,
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'profile',
            builder: (context, state) =>
                const StaffRoleGuard(child: ProfileScreen()),
          ),
          GoRoute(
            path: 'warehouses',
            builder: (context, state) => const StaffRoleGuard(
              child: WarehouseMapScreen(
                key: Key('staffWarehousesScreen'),
                staffMode: true,
              ),
            ),
          ),
          GoRoute(
            path: 'products',
            builder: (context, state) => const StaffRoleGuard(
              child: AdminProductManagementScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (context, state) =>
            const AdminRoleGuard(child: AdminDashboardScreen()),
        routes: [
          GoRoute(
            path: 'products',
            builder: (context, state) =>
                const AdminRoleGuard(child: AdminProductManagementScreen()),
          ),
          GoRoute(
            path: 'users',
            builder: (context, state) =>
                const AdminRoleGuard(child: AdminUserManagementScreen()),
          ),
          GoRoute(
            path: 'orders',
            builder: (context, state) =>
                const AdminRoleGuard(child: OrderListScreen(adminMode: true)),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => AdminRoleGuard(
                  child: OrderDetailScreen(
                    orderId: state.pathParameters['id']!,
                    adminMode: true,
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'notifications',
            builder: (context, state) =>
                const AdminRoleGuard(child: NotificationsScreen()),
          ),
          GoRoute(
            path: 'profile',
            builder: (context, state) =>
                const AdminRoleGuard(child: ProfileScreen()),
          ),
        ],
      ),
    ],
  );

  static Widget _vnpayResultBuilder(BuildContext context, GoRouterState state) {
    return VnpayResultScreen(
      queryParameters: Map<String, String>.unmodifiable(
        state.uri.queryParameters,
      ),
    );
  }

  static void _routeByRole(BuildContext context, User user) {
    if (user.isAdmin) {
      context.go(AppRoutes.adminDashboard);
      return;
    }
    if (user.isStaff) {
      context.go(AppRoutes.staffDashboard);
      return;
    }
    context.go(AppRoutes.home);
  }
}

class _SplashPage extends StatefulWidget {
  const _SplashPage();

  @override
  State<_SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<_SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      _routeForAuthState(context, context.read<AuthBloc>().state);
    });
  }

  void _routeForAuthState(BuildContext context, AuthState state) {
    if (state is AuthAuthenticated) {
      AppRouter._routeByRole(context, state.user);
      return;
    }
    if (state is AuthUnauthenticated || state is AuthFailure) {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocListener<AuthBloc, AuthState>(
      listener: _routeForAuthState,
      child: Scaffold(
        backgroundColor: theme.colorScheme.primary,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(AppAssets.appIcon, width: 104, height: 104),
              const SizedBox(height: 18),
              Text(
                'MarineLink',
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'B2B Seafood Ordering',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuyerShellBackScope extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _BuyerShellBackScope({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    BuyerNavigation.attachShell(navigationShell);

    return AppBackExitScope(
      onFirstBack: (context) async {
        final handled = BuyerNavigation.popOrGo(context, AppRoutes.home);
        if (handled) return;

        final shouldExit = AppBackExitController.recordRootBackPress();
        if (shouldExit) {
          await AppBackExitController.exitApp();
        }
      },
      child: navigationShell,
    );
  }
}
