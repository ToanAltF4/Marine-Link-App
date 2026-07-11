/// API endpoint constants — mirrors docs/MarineLink_API_Documentation.md.
/// Do NOT add endpoints here that are not in the API contract document.
abstract class ApiEndpoints {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    //defaultValue: 'http://10.0.2.2:8080', // Android emulator → localhost
    defaultValue: 'http://localhost:8080', // Chạy trên Web Chrome
  );

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String login = '/api/auth/login';
  static const String googleLogin = '/api/auth/google';
  static const String register = '/api/auth/register';
  static const String emailAvailability = '/api/auth/email-availability';
  static const String phoneAvailability = '/api/auth/phone-availability';
  static const String logout = '/api/auth/logout';
  static const String changePassword = '/api/auth/change-password';
  static const String verifyEmail = '/api/auth/verify-email';
  static const String resendOtp = '/api/auth/resend-otp';
  static const String authForgotPassword = '/api/auth/forgot-password';
  static const String authResetPassword = '/api/auth/reset-password';

  // ── Profile ───────────────────────────────────────────────────────────────
  static const String me = '/api/users/me';
  static const String shippingAddresses = '/api/users/me/shipping-addresses';
  static String shippingAddressDetail(String id) =>
      '/api/users/me/shipping-addresses/$id';

  // ── Products ──────────────────────────────────────────────────────────────
  static const String products = '/api/products';
  static const String productCategories = '/api/products/categories';
  static String productDetail(String id) => '/api/products/$id';

  // ── Storage ───────────────────────────────────────────────────────────────
  static const String storageUpload = '/api/storage/upload';

  // ── Cart ──────────────────────────────────────────────────────────────────
  static const String cart = '/api/cart';
  static const String cartItems = '/api/cart/items';
  static String cartItem(String productId) => '/api/cart/items/$productId';
  static const String cartSync = '/api/cart/sync';

  // ── Orders ────────────────────────────────────────────────────────────────
  static const String orders = '/api/orders';
  static String orderDetail(String id) => '/api/orders/$id';
  static String orderStatus(String id) => '/api/orders/$id/status';

  // ── Payments ──────────────────────────────────────────────────────────────
  static const String vnpayPaymentUrl = '/api/payments/vnpay/payment-url';
  static const String vnpayCancel = '/api/payments/vnpay/cancel';

  // ── Chat ──────────────────────────────────────────────────────────────────
  static const String chatSend = '/api/chat/send';
  static const String chatMyRoom = '/api/chat/room';
  static const String chatMyRooms = '/api/chat/rooms';
  static String chatOrderRoom(String orderId) =>
      '/api/chat/orders/$orderId/room';
  static String chatRoom(String roomId) => '/api/chat/$roomId';
  static const String staffChatRooms = '/api/staff/chat/rooms';
  static String staffChatRoomStatus(String roomId) =>
      '/api/staff/chat/rooms/$roomId/status';
  static String staffChatRoomComplaints(String roomId) =>
      '/api/staff/chat/rooms/$roomId/complaints';

  // ── Notifications ─────────────────────────────────────────────────────────
  static const String notifications = '/api/notifications';
  static String notificationRead(String id) => '/api/notifications/$id/read';
  static const String notificationBroadcasts = '/api/notifications/broadcasts';
  static String notificationBroadcastDetail(String broadcastId) =>
      '/api/notifications/broadcasts/$broadcastId';

  // ── Warehouses ────────────────────────────────────────────────────────────
  static const String warehouses = '/api/warehouses';

  // ── Admin ─────────────────────────────────────────────────────────────────
  static const String adminDashboard = '/api/admin/dashboard';
  static const String adminProducts = '/api/admin/products';
  static String adminProductDetail(String id) => '/api/admin/products/$id';
  static const String adminUsers = '/api/admin/users';
  static String adminUserDetail(String id) => '/api/admin/users/$id';
  static String adminUserRoles(String id) => '/api/admin/users/$id/role';

  // ── Health ────────────────────────────────────────────────────────────────
  static const String health = '/api/health';
}
