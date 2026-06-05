import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'app_back_exit_scope.dart';

class RoleBackToDashboardScope extends StatelessWidget {
  final Widget child;
  final String dashboardLocation;

  const RoleBackToDashboardScope({
    super.key,
    required this.child,
    required this.dashboardLocation,
  });

  @override
  Widget build(BuildContext context) {
    return AppBackExitScope(
      onFirstBack: (context) {
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop();
          return;
        }
        context.go(dashboardLocation);
      },
      child: child,
    );
  }
}
