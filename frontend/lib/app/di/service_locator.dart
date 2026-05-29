import 'package:get_it/get_it.dart';
import '../../core/api/api_client.dart';
import '../../core/storage/secure_token_storage.dart';

final GetIt sl = GetIt.instance;

/// Register all dependencies for dependency injection.
/// Call this before [runApp].
Future<void> setupServiceLocator() async {
  // ── Core: Storage ───────────────────────────────────────────────────────────
  sl.registerLazySingleton<SecureTokenStorage>(() => SecureTokenStorage());

  // ── Core: API Client ────────────────────────────────────────────────────────
  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(tokenStorage: sl<SecureTokenStorage>()),
  );

  // TODO Sprint 1: Register repositories, BLoC/Cubit instances here.
  // Example:
  //   sl.registerLazySingleton<AuthRepository>(
  //     () => AuthMockRepository(),  // switch to AuthRemoteRepository in Sprint 5
  //   );
  //   sl.registerFactory<AuthBloc>(
  //     () => AuthBloc(authRepository: sl<AuthRepository>()),
  //   );
}
