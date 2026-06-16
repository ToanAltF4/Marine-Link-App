import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'di/service_locator.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_event.dart';
import '../features/cart/presentation/cubit/cart_cubit.dart';
import 'router/app_router.dart';
import 'system_back_button_dispatcher.dart';
import 'theme/app_theme.dart';

class MarineLinkApp extends StatelessWidget {
  const MarineLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = AppRouter.router;

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => sl<AuthBloc>()..add(const AuthCheckRequested()),
        ),
        BlocProvider<CartCubit>(create: (_) => sl<CartCubit>()),
      ],
      child: MaterialApp.router(
        title: 'MarineLink',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        routeInformationProvider: router.routeInformationProvider,
        routeInformationParser: router.routeInformationParser,
        routerDelegate: router.routerDelegate,
        backButtonDispatcher: AppSystemBackDispatcher(
          router: router,
          rootContext: () => AppRouter.rootNavigatorKey.currentContext,
        ),
      ),
    );
  }
}
