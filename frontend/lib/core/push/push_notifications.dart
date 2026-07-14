import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

/// App ID công khai của OneSignal (an toàn để nhúng vào app).
/// Có thể override khi build: `--dart-define=ONESIGNAL_APP_ID=...`.
const String kOneSignalAppId = String.fromEnvironment(
  'ONESIGNAL_APP_ID',
  defaultValue: '93b7e231-08ca-4254-963e-93a185103592',
);

/// Khởi tạo OneSignal để thiết bị nhận push notification (kể cả khi app đã tắt
/// hoặc màn hình khóa).
///
/// Thiết kế fail-safe: web không hỗ trợ OneSignal nên bỏ qua; mọi lỗi khởi tạo
/// đều được nuốt để không bao giờ chặn việc mở app. Chỉ khởi tạo — thiết bị tự
/// đăng ký với OneSignal; việc gửi push do backend/dashboard đảm nhiệm.
class PushNotifications {
  const PushNotifications._();

  /// Cầu dao bật/tắt push khi build: `--dart-define=ENABLE_PUSH=false` để tắt
  /// (dùng cho thiết bị không có Google Play Services, tránh crash native).
  static const bool _enabled = bool.fromEnvironment(
    'ENABLE_PUSH',
    defaultValue: true,
  );

  static Future<void> initialize() async {
    if (!_enabled || kIsWeb || kOneSignalAppId.isEmpty) {
      return;
    }
    try {
      OneSignal.initialize(kOneSignalAppId);
      // Xin quyền hiển thị thông báo (Android 13+ / iOS bắt buộc).
      await OneSignal.Notifications.requestPermission(true);
    } catch (_) {
      // Không để lỗi push chặn khởi động app.
    }
  }

  /// Gắn thiết bị với người dùng đang đăng nhập (external_id = public_id) để
  /// backend có thể đẩy push tới đúng đại lý. Gọi sau khi đăng nhập thành công.
  static Future<void> setUser(String userPublicId) async {
    if (!_enabled || kIsWeb || userPublicId.isEmpty) {
      return;
    }
    try {
      await OneSignal.login(userPublicId);
    } catch (_) {}
  }

  /// Bỏ gắn người dùng khỏi thiết bị (khi đăng xuất).
  static Future<void> clearUser() async {
    if (!_enabled || kIsWeb) {
      return;
    }
    try {
      await OneSignal.logout();
    } catch (_) {}
  }
}
