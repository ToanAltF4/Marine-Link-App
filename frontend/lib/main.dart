import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'app/app.dart';
import 'app/di/service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await setupServiceLocator();
  runApp(const MarineLinkApp());
}
