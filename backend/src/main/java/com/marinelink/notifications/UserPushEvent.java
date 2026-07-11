package com.marinelink.notifications;

/**
 * Phát ra sau khi tạo 1 notification cho MỘT người dùng (vd đơn được xác nhận,
 * đổi trạng thái...). Xử lý AFTER_COMMIT để đẩy push OneSignal tới đúng thiết bị
 * của người dùng đó (theo external_id = public_id).
 */
public record UserPushEvent(String externalUserId, String title, String body) {
}
