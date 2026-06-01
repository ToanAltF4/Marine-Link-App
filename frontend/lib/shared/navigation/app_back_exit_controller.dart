import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppBackExitController {
  static const Duration doubleBackWindow = Duration(seconds: 2);

  static DateTime? _lastBackPressTime;

  AppBackExitController._();

  static Future<bool> exitIfSecondPress() async {
    final now = DateTime.now();
    final isSecondPress =
        _lastBackPressTime != null &&
        now.difference(_lastBackPressTime!) < doubleBackWindow;

    if (isSecondPress) {
      _lastBackPressTime = null;
      await SystemNavigator.pop();
      return true;
    }

    _lastBackPressTime = now;
    return false;
  }

  static void showExitHint(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: const Text(
            'Nh\u1ea5n back l\u1ea7n n\u1eefa \u0111\u1ec3 tho\u00e1t \u1ee9ng d\u1ee5ng',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          duration: doubleBackWindow,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
  }

  static void resetForTesting() {
    _lastBackPressTime = null;
  }
}
