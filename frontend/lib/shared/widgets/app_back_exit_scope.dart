import 'dart:async';

import 'package:flutter/widgets.dart';

import '../navigation/app_back_exit_controller.dart';

class AppBackExitScope extends StatelessWidget {
  final Widget child;
  final FutureOr<void> Function(BuildContext context)? onFirstBack;

  const AppBackExitScope({super.key, required this.child, this.onFirstBack});

  @override
  Widget build(BuildContext context) {
    final canPopRoute = Navigator.canPop(context);

    return PopScope(
      canPop: canPopRoute,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          return;
        }

        if (onFirstBack != null) {
          await onFirstBack?.call(context);
          return;
        }

        final didExit = await AppBackExitController.exitIfSecondPress();
        if (didExit || !context.mounted) {
          return;
        }

        AppBackExitController.showExitHint(context);
      },
      child: child,
    );
  }
}
