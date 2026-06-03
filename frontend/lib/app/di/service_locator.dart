import 'package:get_it/get_it.dart';
import '../../core/api/api_client.dart';
import '../../core/storage/secure_token_storage.dart';

// Auth
import '../../features/auth/domain/auth_repository.dart';
import '../../features/auth/data/auth_mock_repository.dart';
import '../../features/auth/data/auth_remote_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

// Products
import '../../features/products/domain/product_repository.dart';
import '../../features/products/data/product_mock_repository.dart';
import '../../features/products/data/product_remote_repository.dart';
import '../../features/products/presentation/bloc/product_bloc.dart';

// Cart
import '../../features/cart/presentation/cubit/cart_cubit.dart';

// Orders
import '../../features/orders/domain/order_repository.dart';
import '../../features/orders/data/order_mock_repository.dart';
import '../../features/orders/presentation/bloc/order_bloc.dart';

// Checkout
import '../../features/checkout/domain/checkout_repository.dart';
import '../../features/checkout/data/order_checkout_repository.dart';
import '../../features/checkout/presentation/bloc/checkout_bloc.dart';

final GetIt sl = GetIt.instance;

const bool _useRemoteRepositories = bool.fromEnvironment(
  'USE_REMOTE_REPOSITORIES',
  defaultValue: false,
);

/// Register all dependencies for dependency injection.
/// Call this before [runApp] in main.dart.
///
/// Sprint 5 migration: swap Mock repositories for Remote ones here without
/// touching any BLoC/Cubit or UI code.
Future<void> setupServiceLocator() async {
  // ── Core: Storage ────────────────────────────────────────────────────────────
  sl.registerLazySingleton<SecureTokenStorage>(() => SecureTokenStorage());

  // ── Core: API Client ─────────────────────────────────────────────────────────
  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(tokenStorage: sl<SecureTokenStorage>()),
  );

  // ── Auth ─────────────────────────────────────────────────────────────────────
  // Sprint 5: swap AuthMockRepository → AuthRemoteRepository
  sl.registerLazySingleton<AuthRepository>(
    () => _useRemoteRepositories
        ? AuthRemoteRepository(
            apiClient: sl<ApiClient>(),
            tokenStorage: sl<SecureTokenStorage>(),
          )
        : AuthMockRepository(),
  );
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(authRepository: sl<AuthRepository>()),
  );

  // ── Products ─────────────────────────────────────────────────────────────────
  // Sprint 5: swap ProductMockRepository → ProductRemoteRepository
  sl.registerLazySingleton<ProductRepository>(
    () => _useRemoteRepositories
        ? ProductRemoteRepository(apiClient: sl<ApiClient>())
        : ProductMockRepository(),
  );
  sl.registerFactory<ProductBloc>(
    () => ProductBloc(productRepository: sl<ProductRepository>()),
  );

  // ── Cart ──────────────────────────────────────────────────────────────────────
  // CartCubit is a singleton so the cart persists across screens within a session.
  sl.registerLazySingleton<CartCubit>(() => CartCubit());

  // ── Orders ───────────────────────────────────────────────────────────────────
  // Sprint 5: swap OrderMockRepository → OrderRemoteRepository
  sl.registerLazySingleton<OrderRepository>(() => OrderMockRepository());
  sl.registerFactory<OrderBloc>(
    () => OrderBloc(orderRepository: sl<OrderRepository>()),
  );

  // Checkout uses OrderRepository as the POST /api/orders adapter.
  sl.registerLazySingleton<CheckoutRepository>(
    () => OrderCheckoutRepository(orderRepository: sl<OrderRepository>()),
  );
  sl.registerFactory<CheckoutBloc>(
    () => CheckoutBloc(checkoutRepository: sl<CheckoutRepository>()),
  );
}
