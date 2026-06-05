import 'package:flutter/services.dart';

class AppBackExitController {
  /// Khoảng thời gian tối đa giữa 2 lần nhấn back để thoát app.
  static const Duration _doubleBackThreshold = Duration(milliseconds: 800);

  AppBackExitController._();

  static DateTime? _lastBackPressTime;

  /// Ghi nhận lần nhấn back.
  /// Trả về `true` nếu là lần nhấn thứ 2 trong vòng [_doubleBackThreshold] → cần thoát app.
  static bool recordRootBackPress() {
    final now = DateTime.now();
    if (_lastBackPressTime != null &&
        now.difference(_lastBackPressTime!) <= _doubleBackThreshold) {
      _lastBackPressTime = null;
      return true;
    }
    _lastBackPressTime = now;
    return false;
  }

  /// Thoát app.
  static Future<void> exitApp() async {
    await SystemNavigator.pop();
  }

  static void resetForTesting() {
    _lastBackPressTime = null;
  }
}
