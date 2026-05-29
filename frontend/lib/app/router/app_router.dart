import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../di/service_locator.dart';

/// Named route constants — use these instead of string literals everywhere.
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

  // Admin routes
  static const adminDashboard = '/admin';
  static const adminProducts = '/admin/products';
  static const adminUsers = '/admin/users';
  static const adminOrders = '/admin/orders';
}

/// Central router configuration using GoRouter.
/// Role guard is applied via [_roleGuard]; actual AuthBloc-based redirect
/// will be wired in Sprint 1 when AuthBloc is complete.
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
        builder: (context, state) => const _PlaceholderPage(title: 'Login'),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const _PlaceholderPage(title: 'Register'),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const _PlaceholderPage(title: 'Home'),
      ),
      GoRoute(
        path: AppRoutes.productList,
        builder: (context, state) =>
            const _PlaceholderPage(title: 'Product List'),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) => _PlaceholderPage(
              title: 'Product Detail: ${state.pathParameters['id']}',
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.cart,
        builder: (context, state) => const _PlaceholderPage(title: 'Cart'),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        builder: (context, state) => const _PlaceholderPage(title: 'Checkout'),
      ),
      GoRoute(
        path: AppRoutes.orders,
        builder: (context, state) => const _PlaceholderPage(title: 'Orders'),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) => _PlaceholderPage(
              title: 'Order Detail: ${state.pathParameters['id']}',
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) =>
            const _PlaceholderPage(title: 'Notifications'),
      ),
      GoRoute(
        path: AppRoutes.chat,
        builder: (context, state) => const _PlaceholderPage(title: 'Chat'),
        routes: [
          GoRoute(
            path: ':roomId',
            builder: (context, state) => _PlaceholderPage(
              title: 'Chat Room: ${state.pathParameters['roomId']}',
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const _PlaceholderPage(title: 'Profile'),
      ),
      GoRoute(
        path: AppRoutes.warehouseMap,
        builder: (context, state) =>
            const _PlaceholderPage(title: 'Warehouse Map'),
      ),
      // ── Admin routes ─────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (context, state) =>
            const _PlaceholderPage(title: 'Admin Dashboard'),
        routes: [
          GoRoute(
            path: 'products',
            builder: (context, state) =>
                const _PlaceholderPage(title: 'Admin: Products'),
          ),
          GoRoute(
            path: 'users',
            builder: (context, state) =>
                const _PlaceholderPage(title: 'Admin: Users'),
          ),
          GoRoute(
            path: 'orders',
            builder: (context, state) =>
                const _PlaceholderPage(title: 'Admin: Orders'),
          ),
        ],
      ),
    ],
    // TODO Sprint 1: wire redirect to AuthBloc state
    // redirect: (context, state) => _roleGuard(context, state),
  );
}

// ── Temporary screens ─────────────────────────────────────────────────────────

class _SplashPage extends StatefulWidget {
  const _SplashPage();

  @override
  State<_SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<_SplashPage> {
  @override
  void initState() {
    super.initState();
    // After short delay, navigate to login (will be replaced by auth check)
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
            Icon(Icons.anchor, size: 80, color: theme.colorScheme.onPrimary),
            const SizedBox(height: 16),
            Text(
              'MarineLink',
              style: theme.textTheme.headlineLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'B2B Seafood Ordering',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimary.withOpacity(0.8),
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
  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title\n(Sprint 1 implementation pending)',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
