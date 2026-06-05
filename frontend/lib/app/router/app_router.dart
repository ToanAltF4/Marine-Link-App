import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets/app_assets.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/widgets/admin_role_guard.dart';
import '../../features/auth/domain/user.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/checkout/presentation/screens/checkout_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/orders/presentation/screens/order_detail_screen.dart';
import '../../features/orders/presentation/screens/order_list_screen.dart';
import '../../features/products/presentation/screens/product_detail_screen.dart';
import '../../features/products/presentation/screens/product_list_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../shared/widgets/app_back_exit_scope.dart';
import '../../shared/widgets/buyer_back_to_home_scope.dart';
import '../../shared/widgets/buyer_bottom_nav.dart';

abstract class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const productList = '/products';
  static const productDetail = '/products/:id';
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const orders = '/orders';
  static const orderDetail = '/orders/:id';
  static const notifications = '/notifications';
  static const chat = '/chat';
  static const chatRoom = '/chat/:roomId';
  static const profile = '/profile';
  static const warehouseMap = '/warehouses';

  static const adminDashboard = '/admin';
  static const adminProducts = '/admin/products';
  static const adminUsers = '/admin/users';
  static const adminOrders = '/admin/orders';

  static String productDetailPath(String id) => '$productList/$id';
  static String orderDetailPath(String id) => '$orders/$id';
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

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => navigationShell,
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
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
                builder: (context, state) => const _PlaceholderPage(
                  title: 'Chat',
                  buyerBottomNavTab: BuyerBottomNavTab.chat,
                ),
                routes: [
                  GoRoute(
                    path: ':roomId',
                    builder: (context, state) => _PlaceholderPage(
                      title: 'Chat Room: ${state.pathParameters['roomId']}',
                    ),
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
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.warehouseMap,
        builder: (context, state) =>
            const _PlaceholderPage(title: 'Warehouse Map'),
      ),
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (context, state) =>
            const AdminRoleGuard(child: AdminDashboardScreen()),
        routes: [
          GoRoute(
            path: 'products',
            builder: (context, state) => const AdminRoleGuard(
              child: _PlaceholderPage(title: 'Admin: Products'),
            ),
          ),
          GoRoute(
            path: 'users',
            builder: (context, state) => const AdminRoleGuard(
              child: _PlaceholderPage(title: 'Admin: Users'),
            ),
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
        ],
      ),
    ],
  );

  static void _routeByRole(BuildContext context, User user) {
    if (user.isAdmin || user.isStaff) {
      context.go(AppRoutes.adminDashboard);
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
      if (mounted) context.go(AppRoutes.login);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
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
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  final String title;
  final BuyerBottomNavTab? buyerBottomNavTab;

  const _PlaceholderPage({required this.title, this.buyerBottomNavTab});

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      appBar: AppBar(title: Text(title)),
      bottomNavigationBar: buyerBottomNavTab == null
          ? null
          : BuyerBottomNav(currentTab: buyerBottomNavTab),
      body: Center(
        child: Text(
          '$title\n(Sprint 1 implementation pending)',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
    if (buyerBottomNavTab != null) {
      return BuyerBackToHomeScope(child: scaffold);
    }
    return AppBackExitScope(
      onFirstBack: (context) {
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop();
          return;
        }
        context.go(AppRoutes.home);
      },
      child: scaffold,
    );
  }
}
