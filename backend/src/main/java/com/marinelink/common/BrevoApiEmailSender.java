package com.marinelink.common;

import jakarta.mail.Address;
import jakarta.mail.BodyPart;
import jakarta.mail.Multipart;
import jakarta.mail.internet.MimeMessage;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * Gửi email qua **Brevo HTTP API** (https://api.brevo.com, cổng 443).
 *
 * <p>Lý do: Render chặn mọi cổng SMTP ra ngoài (25/465/587) nên không gửi được
 * bằng SMTP. API chạy trên HTTPS/443 nên luôn thông.
 *
 * <p>Chỉ bật khi có {@code BREVO_API_KEY}; nếu không, {@link AsyncEmailSender}
 * dùng đường khác (Gmail API hoặc SMTP cho local).
 */
@Component
@Slf4j
public class BrevoApiEmailSender {

    private static final String SEND_URL = "https://api.brevo.com/v3/smtp/email";

    private final String apiKey;
    private final String fromEmail;
    private final String fromName;
    private final RestClient restClient;

    @Autowired
    public BrevoApiEmailSender(
            @Value("${app.mail.brevo.api-key:}") String apiKey,
            @Value("${app.mail.from:}") String fromEmail,
            @Value("${app.mail.from-name:MarineLink}") String fromName) {
        this(apiKey, fromEmail, fromName, RestClient.create());
    }

    BrevoApiEmailSender(
            String apiKey, String fromEmail, String fromName, RestClient restClient) {
        this.apiKey = apiKey == null ? "" : apiKey.trim();
        this.fromEmail = fromEmail == null ? "" : fromEmail.trim();
        this.fromName = fromName == null || fromName.isBlank() ? "MarineLink" : fromName.trim();
        this.restClient = restClient;
    }

    public boolean isConfigured() {
        return !apiKey.isBlank() && !fromEmail.isBlank();
    }

    /** Gửi email; ném exception nếu thất bại để {@link AsyncEmailSender} log lại. */
    public void send(MimeMessage message) throws Exception {
        List<Map<String, String>> to = recipients(message);
        if (to.isEmpty()) {
            throw new IllegalArgumentException("Email không có người nhận");
        }

        Map<String, Object> payload = Map.of(
                "sender", Map.of("name", fromName, "email", fromEmail),
                "to", to,
                "subject", message.getSubject() == null ? "" : message.getSubject(),
                "htmlContent", htmlContent(message));

        restClient.post()
                .uri(SEND_URL)
                .header("api-key", apiKey)
                .header("accept", "application/json")
                .contentType(MediaType.APPLICATION_JSON)
                .body(payload)
                .retrieve()
                .toBodilessEntity();
    }

    private List<Map<String, String>> recipients(MimeMessage message) throws Exception {
        List<Map<String, String>> to = new ArrayList<>();
        Address[] addresses = message.getAllRecipients();
        if (addresses != null) {
            for (Address address : addresses) {
                to.add(Map.of("email", address.toString()));
            }
        }
        return to;
    }

    /**
     * Lấy phần HTML trong MimeMessage (các email đều dựng bằng setText(html, true)).
     *
     * <p>Gọi {@code saveChanges()} trước để MIME được hoàn chỉnh — JavaMailSender
     * vẫn làm bước này khi gửi qua SMTP, còn ở đây ta tự đọc nội dung ra.
     */
    static String htmlContent(MimeMessage message) throws Exception {
        message.saveChanges();
        String html = findHtml(message.getContent());
        return html == null ? "" : html;
    }

    private static String findHtml(Object content) throws Exception {
        if (content instanceof String text) {
            return text;
        }
        if (content instanceof Multipart multipart) {
            for (int i = 0; i < multipart.getCount(); i++) {
                BodyPart part = multipart.getBodyPart(i);
                if (part.isMimeType("text/html")) {
                    return String.valueOf(part.getContent());
                }
                Object inner = part.getContent();
                if (inner instanceof Multipart) {
                    String found = findHtml(inner);
                    if (found != null) {
                        return found;
                    }
                }
            }
        }
        return null;
    }
}
