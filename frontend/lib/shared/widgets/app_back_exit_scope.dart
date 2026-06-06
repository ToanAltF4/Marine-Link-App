import 'dart:async';

import 'package:flutter/widgets.dart';

import '../navigation/app_back_exit_controller.dart';

class AppBackExitScope extends StatelessWidget {
  final Widget child;
  final FutureOr<void> Function(BuildContext context)? onFirstBack;

  const AppBackExitScope({super.key, required this.child, this.onFirstBack});

  @override
  Widget build(BuildContext context) {
    final popScope = PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleBack(context);
      },
      child: child,
    );

    if (Router.maybeOf(context) == null) {
      return popScope;
    }

    return BackButtonListener(
      onBackButtonPressed: () async {
        await _handleBack(context);
        return true;
      },
      child: popScope,
    );
  }

  Future<void> _handleBack(BuildContext context) async {
    if (onFirstBack != null) {
      await onFirstBack?.call(context);
      return;
    }

    final shouldExit = AppBackExitController.recordRootBackPress();
    if (shouldExit) {
      await AppBackExitController.exitApp();
    }
  }
}
