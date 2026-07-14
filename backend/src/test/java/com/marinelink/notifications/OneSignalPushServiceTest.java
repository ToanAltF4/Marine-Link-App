package com.marinelink.notifications;

import org.junit.jupiter.api.Test;
import org.springframework.web.client.RestClient;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;

class OneSignalPushServiceTest {

    private OneSignalPushService service(boolean enabled, String appId, String key) {
        return new OneSignalPushService(
                enabled, appId, key,
                "https://onesignal.com/api/v1/notifications",
                "Basic", "Subscribed Users", RestClient.create());
    }

    @Test
    void notConfiguredWhenKeysBlank() {
        assertThat(service(true, "", "").isConfigured()).isFalse();
        assertThat(service(true, "app-id", "").isConfigured()).isFalse();
        assertThat(service(true, "", "key").isConfigured()).isFalse();
    }

    @Test
    void notConfiguredWhenDisabledEvenWithKeys() {
        assertThat(service(false, "app-id", "key").isConfigured()).isFalse();
    }

    @Test
    void configuredWhenEnabledWithBothKeys() {
        assertThat(service(true, "app-id", "key").isConfigured()).isTrue();
    }

    @Test
    void sendIsNoOpAndNeverThrowsWhenNotConfigured() {
        assertThatCode(() -> service(true, "", "").send("Nghỉ lễ", "Nội dung"))
                .doesNotThrowAnyException();
    }

    @Test
    @SuppressWarnings("unchecked")
    void userPayloadTargetsExternalId() {
        Map<String, Object> payload =
                service(true, "app-id", "key").buildUserPayload("user-123", "Tiêu đề", "Nội dung");

        assertThat(payload.get("target_channel")).isEqualTo("push");
        Map<String, Object> aliases = (Map<String, Object>) payload.get("include_aliases");
        assertThat((List<String>) aliases.get("external_id")).containsExactly("user-123");
        assertThat((Map<String, String>) payload.get("contents")).containsEntry("vi", "Nội dung");
    }

    @Test
    void sendToExternalUserNoOpWhenNotConfiguredOrBlankId() {
        assertThatCode(() -> service(true, "", "").sendToExternalUser("u", "t", "b"))
                .doesNotThrowAnyException();
        assertThatCode(() -> service(true, "app", "key").sendToExternalUser("", "t", "b"))
                .doesNotThrowAnyException();
    }

    @Test
    @SuppressWarnings("unchecked")
    void payloadTargetsSegmentWithBilingualContent() {
        Map<String, Object> payload =
                service(true, "app-id-123", "key").buildPayload("Nghỉ lễ 30/4", "Kho nghỉ 2 ngày");

        assertThat(payload.get("app_id")).isEqualTo("app-id-123");
        assertThat((List<String>) payload.get("included_segments")).containsExactly("Subscribed Users");
        assertThat((Map<String, String>) payload.get("headings")).containsEntry("vi", "Nghỉ lễ 30/4");
        assertThat((Map<String, String>) payload.get("contents")).containsEntry("vi", "Kho nghỉ 2 ngày");
    }
}
