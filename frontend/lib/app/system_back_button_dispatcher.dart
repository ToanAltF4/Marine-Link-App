import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../shared/navigation/app_back_exit_controller.dart';
import 'router/app_router.dart';

class AppSystemBackDispatcher extends RootBackButtonDispatcher {
  final GoRouter router;
  final BuildContext? Function() rootContext;

  AppSystemBackDispatcher({required this.router, required this.rootContext});

  @override
  Future<bool> didPopRoute() async {
    final handledByRoute = await invokeCallback(Future<bool>.value(false));
    if (handledByRoute) {
      return true;
    }

    return _handleRootFallback();
  }

  bool _handleRootFallback() {
    final location = router.routerDelegate.currentConfiguration.uri.path;

    if (location.startsWith('${AppRoutes.adminDashboard}/')) {
      router.go(AppRoutes.adminDashboard);
      return true;
    }

    if (location.startsWith('${AppRoutes.staffDashboard}/')) {
      router.go(AppRoutes.staffDashboard);
      return true;
    }

    if (location == AppRoutes.register) {
      router.go(AppRoutes.login);
      return true;
    }

    final context = rootContext();
    if (context != null && context.mounted) {
      final shouldExit = AppBackExitController.recordRootBackPress();
      if (shouldExit) {
        AppBackExitController.exitApp();
      }
    }
    return true;
  }
}
