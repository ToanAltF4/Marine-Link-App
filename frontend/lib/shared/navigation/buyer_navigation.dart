import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

class BuyerNavigation {
  BuyerNavigation._();

  static void push(BuildContext context, String location) {
    final router = GoRouter.maybeOf(context);
    if (router == null || _isCurrentLocation(context, location)) {
      return;
    }
    router.push(location);
  }

  static void popOrGo(BuildContext context, String fallbackLocation) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    GoRouter.maybeOf(context)?.go(fallbackLocation);
  }

  static bool _isCurrentLocation(BuildContext context, String location) {
    try {
      return GoRouterState.of(context).uri.toString() == location;
    } on Exception {
      return false;
    }
  }
}
