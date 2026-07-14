import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:marinelink/core/constants/app_strings.dart';

import '../domain/notification.dart';
import '../domain/notification_display_service.dart';

class LocalNotificationDisplayService implements NotificationDisplayService {
  static const _channelId = 'marinelink_new_notifications';
  static const _channelName = AppStrings.localNotificationChannelName;
  static const _channelDescription =
      AppStrings.localNotificationChannelDescription;

  static const _channel = AndroidNotificationChannel(
    _channelId,
    _channelName,
    description: _channelDescription,
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  final FlutterLocalNotificationsPlugin _plugin;
  final DateTime Function() _now;
  final Set<String> _knownNotificationIds = {};
  late final DateTime _startedAt = _now();
  bool _initialized = false;
  bool _canShowNotifications = false;

  LocalNotificationDisplayService({
    FlutterLocalNotificationsPlugin? plugin,
    DateTime Function()? now,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _now = now ?? DateTime.now;

  @override
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    if (!_isAndroidPhoneTarget) {
      _initialized = true;
      return;
    }

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    try {
      await _plugin.initialize(settings: initializationSettings);

      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.createNotificationChannel(_channel);
      await android?.requestNotificationsPermission();

      _canShowNotifications = android != null;
      _initialized = true;
    } catch (_) {
      _canShowNotifications = false;
      _initialized = true;
    }
  }

  @override
  Future<void> syncNewNotifications(
    List<NotificationEntity> notifications,
  ) async {
    final newUnreadNotifications =
        notifications.where(_shouldShowOnDevice).toList()..sort(
          (first, second) => first.createdAt.compareTo(second.createdAt),
        );

    _knownNotificationIds.addAll(notifications.map((item) => item.id));

    if (newUnreadNotifications.isEmpty) {
      return;
    }

    await initialize();
    if (!_canShowNotifications) {
      return;
    }

    for (final item in newUnreadNotifications) {
      try {
        await _plugin.show(
          id: _stableNotificationId(item.id),
          title: item.title,
          body: item.message,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: _channelDescription,
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
              enableVibration: true,
              visibility: NotificationVisibility.public,
              ticker: 'MarineLink',
              category: AndroidNotificationCategory.status,
            ),
          ),
          payload: _payloadFor(item),
        );
      } catch (_) {}
    }
  }

  bool _shouldShowOnDevice(NotificationEntity item) {
    return !item.isRead &&
        !_knownNotificationIds.contains(item.id) &&
        item.createdAt.isAfter(_startedAt);
  }

  bool get _isAndroidPhoneTarget =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  String _payloadFor(NotificationEntity item) {
    return jsonEncode({
      'id': item.id,
      'type': item.type.apiValue,
      'relatedOrderId': item.relatedOrderId,
      'relatedProductId': item.relatedProductId,
      'relatedChatRoomId': item.relatedChatRoomId,
    });
  }

  int _stableNotificationId(String id) {
    var hash = 0x811c9dc5;
    for (final codeUnit in id.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }
}
