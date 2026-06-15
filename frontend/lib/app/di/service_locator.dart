import 'package:get_it/get_it.dart';
import '../../core/api/api_client.dart';
import '../../core/storage/secure_token_storage.dart';

// Auth
import '../../features/auth/domain/auth_repository.dart';
import '../../features/auth/data/auth_mock_repository.dart';
import '../../features/auth/data/auth_remote_repository.dart';
import '../../features/auth/data/google_sign_in_service.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

// Products
import '../../features/products/domain/product_repository.dart';
import '../../features/products/data/product_mock_repository.dart';
import '../../features/products/data/product_remote_repository.dart';
import '../../features/products/presentation/bloc/product_bloc.dart';

// Cart
import '../../features/cart/domain/cart_repository.dart';
import '../../features/cart/data/cart_remote_repository.dart';
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

// Warehouses
import '../../features/warehouse_map/domain/warehouse_repository.dart';
import '../../features/warehouse_map/domain/warehouse_location_service.dart';
import '../../features/warehouse_map/data/geolocator_warehouse_location_service.dart';
import '../../features/warehouse_map/data/warehouse_mock_repository.dart';
import '../../features/warehouse_map/data/warehouse_remote_repository.dart';
import '../../features/warehouse_map/presentation/cubit/warehouse_location_cubit.dart';
import '../../features/warehouse_map/presentation/cubit/warehouse_map_cubit.dart';

// Chat
import '../../features/chat/domain/chat_repository.dart';
import '../../features/chat/data/chat_mock_repository.dart';
import '../../features/chat/data/chat_remote_repository.dart';
import '../../features/chat/presentation/cubit/chat_cubit.dart';
import '../../features/chat/presentation/cubit/staff_chat_cubit.dart';

// Profile
import '../../features/profile/domain/profile_repository.dart';
import '../../features/profile/data/profile_mock_repository.dart';
import '../../features/profile/data/profile_remote_repository.dart';
import '../../features/profile/presentation/bloc/profile_cubit.dart';

// Admin
import '../../features/admin/domain/admin_dashboard_repository.dart';
import '../../features/admin/data/admin_dashboard_mock_repository.dart';
import '../../features/admin/data/admin_dashboard_remote_repository.dart';
import '../../features/admin/presentation/cubit/admin_dashboard_cubit.dart';

// Admin Products
import '../../features/admin_products/domain/admin_product_repository.dart';
import '../../features/admin_products/data/admin_product_mock_repository.dart';
import '../../features/admin_products/data/admin_product_remote_repository.dart';
import '../../features/admin_products/presentation/cubit/admin_product_cubit.dart';

// Admin Users
import '../../features/admin_users/domain/admin_user_repository.dart';
import '../../features/admin_users/data/admin_user_mock_repository.dart';
import '../../features/admin_users/data/admin_user_remote_repository.dart';
import '../../features/admin_users/presentation/cubit/admin_user_cubit.dart';

// Checkout
import '../../features/checkout/domain/checkout_repository.dart';
import '../../features/checkout/data/cart_sync_repository.dart';
import '../../features/checkout/data/order_checkout_repository.dart';
import '../../features/checkout/domain/shipping_address_repository.dart';
import '../../features/checkout/data/shipping_address_mock_repository.dart';
import '../../features/checkout/data/shipping_address_remote_repository.dart';
import '../../features/checkout/domain/vnpay_payment.dart';
import '../../features/checkout/data/vnpay_payment_remote_repository.dart';
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
  sl.registerLazySingleton<GoogleAuthService>(() => GoogleSignInAuthService());
  // Sprint 5: swap AuthMockRepository → AuthRemoteRepository
  sl.registerLazySingleton<AuthRepository>(
    () => _useRemoteRepositories
        ? AuthRemoteRepository(
            apiClient: sl<ApiClient>(),
            tokenStorage: sl<SecureTokenStorage>(),
            googleAuthService: sl<GoogleAuthService>(),
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
  if (_useRemoteRepositories) {
    sl.registerLazySingleton<CartRepository>(
      () => CartRemoteRepository(apiClient: sl<ApiClient>()),
    );
  }
  sl.registerLazySingleton<CartCubit>(
    () => CartCubit(
      cartRepository: _useRemoteRepositories ? sl<CartRepository>() : null,
    ),
  );

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
    () =>
        NotificationCubit(notificationRepository: sl<NotificationRepository>()),
  );

  // Warehouses
  sl.registerLazySingleton<WarehouseRepository>(
    () => _useRemoteRepositories
        ? WarehouseRemoteRepository(apiClient: sl<ApiClient>())
        : WarehouseMockRepository(),
  );
  sl.registerLazySingleton<WarehouseLocationService>(
    () => GeolocatorWarehouseLocationService(),
  );
  sl.registerFactory<WarehouseMapCubit>(
    () => WarehouseMapCubit(repository: sl<WarehouseRepository>()),
  );
  sl.registerFactory<WarehouseLocationCubit>(
    () => WarehouseLocationCubit(service: sl<WarehouseLocationService>()),
  );

  // Chat
  sl.registerLazySingleton<ChatRepository>(
    () => _useRemoteRepositories
        ? ChatRemoteRepository(apiClient: sl<ApiClient>())
        : ChatMockRepository(),
  );
  sl.registerFactory<ChatCubit>(
    () => ChatCubit(repository: sl<ChatRepository>()),
  );
  sl.registerFactory<StaffChatCubit>(
    () => StaffChatCubit(repository: sl<ChatRepository>()),
  );

  // Checkout uses OrderRepository as the POST /api/orders adapter.
  sl.registerLazySingleton<ShippingAddressRepository>(
    () => _useRemoteRepositories
        ? ShippingAddressRemoteRepository(apiClient: sl<ApiClient>())
        : ShippingAddressMockRepository(),
  );
  sl.registerLazySingleton<CartSyncRepository>(
    () => CartSyncRemoteRepository(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<VnpayPaymentRepository>(
    () => VnpayPaymentRemoteRepository(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<CheckoutRepository>(
    () => OrderCheckoutRepository(
      orderRepository: sl<OrderRepository>(),
      cartSyncRepository: _useRemoteRepositories
          ? sl<CartSyncRepository>()
          : null,
      vnpayPaymentRepository: _useRemoteRepositories
          ? sl<VnpayPaymentRepository>()
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

  // ── Admin ────────────────────────────────────────────────────────────────────
  // Sprint 5: swap AdminDashboardMockRepository → AdminDashboardRemoteRepository
  sl.registerLazySingleton<AdminDashboardRepository>(
    () => _useRemoteRepositories
        ? AdminDashboardRemoteRepository(apiClient: sl<ApiClient>())
        : AdminDashboardMockRepository(),
  );
  sl.registerFactory<AdminDashboardCubit>(
    () => AdminDashboardCubit(repository: sl<AdminDashboardRepository>()),
  );

  // ── Admin Users ─────────────────────────────────────────────────────────────
  // Sprint 5: swap AdminUserMockRepository → AdminUserRemoteRepository
  sl.registerLazySingleton<AdminProductRepository>(
    () => _useRemoteRepositories
        ? AdminProductRemoteRepository(apiClient: sl<ApiClient>())
        : AdminProductMockRepository(),
  );
  sl.registerFactory<AdminProductCubit>(
    () => AdminProductCubit(repository: sl<AdminProductRepository>()),
  );

  sl.registerLazySingleton<AdminUserRepository>(
    () => _useRemoteRepositories
        ? AdminUserRemoteRepository(apiClient: sl<ApiClient>())
        : AdminUserMockRepository(),
  );
  sl.registerFactory<AdminUserCubit>(
    () => AdminUserCubit(repository: sl<AdminUserRepository>()),
  );
}
