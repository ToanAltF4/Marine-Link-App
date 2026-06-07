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
import '../../features/orders/data/order_remote_repository.dart';
import '../../features/orders/presentation/bloc/order_bloc.dart';

// Notifications
import '../../features/notifications/domain/notification_repository.dart';
import '../../features/notifications/data/notification_mock_repository.dart';
import '../../features/notifications/data/notification_remote_repository.dart';
import '../../features/notifications/presentation/bloc/notification_cubit.dart';

// Profile
import '../../features/profile/domain/profile_repository.dart';
import '../../features/profile/data/profile_mock_repository.dart';
import '../../features/profile/data/profile_remote_repository.dart';
import '../../features/profile/presentation/bloc/profile_cubit.dart';

// Checkout
import '../../features/checkout/domain/checkout_repository.dart';
import '../../features/checkout/data/cart_sync_repository.dart';
import '../../features/checkout/data/order_checkout_repository.dart';
import '../../features/checkout/domain/shipping_address_repository.dart';
import '../../features/checkout/data/shipping_address_remote_repository.dart';
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
  sl.registerLazySingleton<OrderRepository>(
    () => _useRemoteRepositories
        ? OrderRemoteRepository(apiClient: sl<ApiClient>())
        : OrderMockRepository(),
  );
  sl.registerFactory<OrderBloc>(
    () => OrderBloc(orderRepository: sl<OrderRepository>()),
  );

  // ── Notifications ────────────────────────────────────────────────────────────
  sl.registerLazySingleton<NotificationRepository>(
    () => _useRemoteRepositories
        ? NotificationRemoteRepository(apiClient: sl<ApiClient>())
        : NotificationMockRepository(),
  );
  sl.registerFactory<NotificationCubit>(
    () => NotificationCubit(notificationRepository: sl<NotificationRepository>()),
  );

  // Checkout uses OrderRepository as the POST /api/orders adapter.
  sl.registerLazySingleton<ShippingAddressRepository>(
    () => ShippingAddressRemoteRepository(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<CartSyncRepository>(
    () => CartSyncRemoteRepository(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<CheckoutRepository>(
    () => OrderCheckoutRepository(
      orderRepository: sl<OrderRepository>(),
      cartSyncRepository: _useRemoteRepositories
          ? sl<CartSyncRepository>()
          : null,
    ),
  );
  sl.registerFactory<CheckoutBloc>(
    () => CheckoutBloc(checkoutRepository: sl<CheckoutRepository>()),
  );

  // ── Profile ──────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<ProfileRepository>(
    () => _useRemoteRepositories
        ? ProfileRemoteRepository(apiClient: sl<ApiClient>())
        : ProfileMockRepository(sl<AuthRepository>()),
  );
  sl.registerFactory<ProfileCubit>(
    () => ProfileCubit(profileRepository: sl<ProfileRepository>()),
  );
}
