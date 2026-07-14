package com.marinelink.notifications;

/**
 * Phát ra sau khi Admin/Staff tạo broadcast (đã lưu DB). Được xử lý AFTER_COMMIT
 * để đẩy push (OneSignal) ngoài transaction — push lỗi không ảnh hưởng broadcast.
 */
public record BroadcastCreatedEvent(String title, String body) {
}
