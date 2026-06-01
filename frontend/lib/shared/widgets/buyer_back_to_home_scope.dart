import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'app_back_exit_scope.dart';

class BuyerBackToHomeScope extends StatelessWidget {
  final Widget child;
  final String homeLocation;

  const BuyerBackToHomeScope({
    super.key,
    required this.child,
    this.homeLocation = '/home',
  });

  @override
  Widget build(BuildContext context) {
    return AppBackExitScope(
      onFirstBack: (context) => GoRouter.maybeOf(context)?.go(homeLocation),
      child: child,
    );
  }
}
