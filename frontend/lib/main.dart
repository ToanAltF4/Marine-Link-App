import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'app/app.dart';
import 'app/di/service_locator.dart';
import 'core/push/push_notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await setupServiceLocator();
  // Khởi tạo push notification (OneSignal) — guard web + fail-safe bên trong.
  await PushNotifications.initialize();
  runApp(const MarineLinkApp());
}
