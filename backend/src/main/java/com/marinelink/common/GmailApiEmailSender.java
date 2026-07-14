package com.marinelink.common;

import jakarta.mail.internet.MimeMessage;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestClient;

import java.io.ByteArrayOutputStream;
import java.time.Instant;
import java.util.Base64;
import java.util.Map;

/**
 * Gửi email qua **Gmail API (HTTPS)** thay vì SMTP.
 *
 * <p>Lý do: Render (và nhiều PaaS) chặn cổng SMTP ra ngoài (25/465/587) nên
 * {@code smtp.gmail.com:587} không kết nối được. Gmail API chạy trên HTTPS/443
 * nên không bị chặn, mà vẫn gửi từ đúng tài khoản Gmail hiện tại.
 *
 * <p>Chỉ bật khi có đủ client-id / client-secret / refresh-token; nếu không,
 * {@link AsyncEmailSender} tự dùng lại SMTP (tiện cho chạy local).
 */
@Component
@Slf4j
public class GmailApiEmailSender {

    private static final String TOKEN_URL = "https://oauth2.googleapis.com/token";
    private static final String SEND_URL =
            "https://gmail.googleapis.com/gmail/v1/users/me/messages/send";

    private final String clientId;
    private final String clientSecret;
    private final String refreshToken;
    private final RestClient restClient;

    /** Access token hiện tại + thời điểm hết hạn (làm mới khi gần hết hạn). */
    private volatile String accessToken;
    private volatile Instant accessTokenExpiresAt = Instant.EPOCH;

    @Autowired
    public GmailApiEmailSender(
            @Value("${app.mail.gmail-api.client-id:}") String clientId,
            @Value("${app.mail.gmail-api.client-secret:}") String clientSecret,
            @Value("${app.mail.gmail-api.refresh-token:}") String refreshToken) {
        this(clientId, clientSecret, refreshToken, RestClient.create());
    }

    GmailApiEmailSender(
            String clientId,
            String clientSecret,
            String refreshToken,
            RestClient restClient) {
        this.clientId = clientId == null ? "" : clientId.trim();
        this.clientSecret = clientSecret == null ? "" : clientSecret.trim();
        this.refreshToken = refreshToken == null ? "" : refreshToken.trim();
        this.restClient = restClient;
    }

    /** Có đủ cấu hình để gửi qua Gmail API hay không. */
    public boolean isConfigured() {
        return !clientId.isBlank() && !clientSecret.isBlank() && !refreshToken.isBlank();
    }

    /**
     * Gửi một MimeMessage qua Gmail API. Ném exception nếu thất bại để phía gọi
     * ({@link AsyncEmailSender}) log lại.
     */
    public void send(MimeMessage message) throws Exception {
        ByteArrayOutputStream buffer = new ByteArrayOutputStream();
        message.writeTo(buffer);
        String raw = Base64.getUrlEncoder().encodeToString(buffer.toByteArray());

        restClient.post()
                .uri(SEND_URL)
                .header("Authorization", "Bearer " + currentAccessToken())
                .contentType(MediaType.APPLICATION_JSON)
                .body(Map.of("raw", raw))
                .retrieve()
                .toBodilessEntity();
    }

    /** Lấy access token còn hạn; tự đổi refresh token -> access token khi cần. */
    private synchronized String currentAccessToken() {
        if (accessToken != null && Instant.now().isBefore(accessTokenExpiresAt)) {
            return accessToken;
        }

        MultiValueMap<String, String> form = new LinkedMultiValueMap<>();
        form.add("client_id", clientId);
        form.add("client_secret", clientSecret);
        form.add("refresh_token", refreshToken);
        form.add("grant_type", "refresh_token");

        @SuppressWarnings("unchecked")
        Map<String, Object> response = restClient.post()
                .uri(TOKEN_URL)
                .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                .body(form)
                .retrieve()
                .body(Map.class);

        if (response == null || response.get("access_token") == null) {
            throw new IllegalStateException("Gmail API không trả về access_token");
        }

        accessToken = response.get("access_token").toString();
        long expiresIn = response.get("expires_in") instanceof Number number
                ? number.longValue()
                : 3600L;
        // Trừ hao 60s để tránh dùng token sát giờ hết hạn.
        accessTokenExpiresAt = Instant.now().plusSeconds(Math.max(60, expiresIn - 60));
        return accessToken;
    }
}
