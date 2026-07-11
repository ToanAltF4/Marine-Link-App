package com.marinelink.notifications;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;
import org.springframework.web.client.RestClient;

import java.util.List;
import java.util.Map;

/**
 * Gửi push notification qua OneSignal khi có broadcast mới.
 *
 * <p>Thiết kế fail-safe: nếu chưa cấu hình key hoặc gọi lỗi thì chỉ log cảnh báo,
 * KHÔNG ném exception — broadcast in-app (lưu DB) luôn thành công dù push có lỗi.
 * Chạy AFTER_COMMIT nên không giữ DB transaction trong lúc gọi HTTP.
 */
@Service
@Slf4j
public class OneSignalPushService {

    private final boolean enabled;
    private final String appId;
    private final String restApiKey;
    private final String baseUrl;
    private final String authScheme;
    private final String segment;
    private final RestClient restClient;

    @Autowired
    public OneSignalPushService(
            @Value("${app.onesignal.enabled:true}") boolean enabled,
            @Value("${app.onesignal.app-id:}") String appId,
            @Value("${app.onesignal.rest-api-key:}") String restApiKey,
            @Value("${app.onesignal.base-url:https://onesignal.com/api/v1/notifications}") String baseUrl,
            @Value("${app.onesignal.auth-scheme:Basic}") String authScheme,
            @Value("${app.onesignal.segment:Total Subscriptions}") String segment) {
        this(enabled, appId, restApiKey, baseUrl, authScheme, segment, RestClient.create());
    }

    // Cho phép inject RestClient trong test.
    OneSignalPushService(boolean enabled, String appId, String restApiKey, String baseUrl,
                         String authScheme, String segment, RestClient restClient) {
        this.enabled = enabled;
        this.appId = appId == null ? "" : appId.trim();
        this.restApiKey = restApiKey == null ? "" : restApiKey.trim();
        this.baseUrl = baseUrl;
        this.authScheme = authScheme;
        this.segment = segment;
        this.restClient = restClient;
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onBroadcastCreated(BroadcastCreatedEvent event) {
        send(event.title(), event.body());
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onUserNotification(UserPushEvent event) {
        sendToExternalUser(event.externalUserId(), event.title(), event.body());
    }

    /** Gửi push tới đúng thiết bị của một người dùng (theo external_id). Fail-safe. */
    public void sendToExternalUser(String externalUserId, String title, String body) {
        if (!isConfigured() || externalUserId == null || externalUserId.isBlank()) {
            return;
        }
        try {
            restClient.post()
                    .uri(baseUrl)
                    .header("Authorization", authScheme + " " + restApiKey)
                    .header("Content-Type", "application/json; charset=utf-8")
                    .body(buildUserPayload(externalUserId, title, body))
                    .retrieve()
                    .toBodilessEntity();
            log.info("Đã gửi push OneSignal tới user {}: {}", externalUserId, title);
        } catch (Exception ex) {
            log.warn("Gửi push OneSignal tới user {} thất bại: {}", externalUserId, ex.getMessage());
        }
    }

    /** Payload nhắm tới 1 người dùng qua alias external_id. */
    Map<String, Object> buildUserPayload(String externalUserId, String title, String body) {
        return Map.of(
                "app_id", appId,
                "target_channel", "push",
                "include_aliases", Map.of("external_id", List.of(externalUserId)),
                "headings", Map.of("en", title, "vi", title),
                "contents", Map.of("en", body, "vi", body)
        );
    }

    /** Gửi push tới toàn bộ thiết bị đã đăng ký. Fail-safe. */
    public void send(String title, String body) {
        if (!isConfigured()) {
            log.debug("OneSignal chưa cấu hình -> bỏ qua push (broadcast in-app vẫn gửi).");
            return;
        }
        try {
            Map<String, Object> payload = buildPayload(title, body);
            restClient.post()
                    .uri(baseUrl)
                    .header("Authorization", authScheme + " " + restApiKey)
                    .header("Content-Type", "application/json; charset=utf-8")
                    .body(payload)
                    .retrieve()
                    .toBodilessEntity();
            log.info("Đã gửi push OneSignal cho broadcast: {}", title);
        } catch (Exception ex) {
            // Không để lỗi push làm hỏng luồng broadcast.
            log.warn("Gửi push OneSignal thất bại: {}", ex.getMessage());
        }
    }

    boolean isConfigured() {
        return enabled && !appId.isEmpty() && !restApiKey.isEmpty();
    }

    /** Body theo OneSignal REST: gửi tới segment mặc định, tiêu đề/nội dung song ngữ. */
    Map<String, Object> buildPayload(String title, String body) {
        return Map.of(
                "app_id", appId,
                "included_segments", List.of(segment),
                "headings", Map.of("en", title, "vi", title),
                "contents", Map.of("en", body, "vi", body)
        );
    }
}
