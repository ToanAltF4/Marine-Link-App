package com.marinelink.common;

import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

/**
 * Cổng gửi email duy nhất của hệ thống — chạy ở luồng nền (@Async).
 *
 * <p>Chọn đường gửi theo cấu hình, ưu tiên từ trên xuống:
 * <ul>
 *   <li><b>Brevo HTTP API</b> nếu có {@code BREVO_API_KEY} — khuyến nghị cho deploy.</li>
 *   <li><b>Gmail API (HTTPS)</b> nếu có client-id/secret/refresh-token.</li>
 *   <li><b>SMTP</b> nếu không cấu hình API nào — tiện cho chạy local.</li>
 * </ul>
 *
 * <p>Vì sao cần API: Render (và nhiều PaaS) chặn cổng SMTP ra ngoài (25/465/587),
 * nên SMTP không kết nối được; API chạy trên HTTPS/443 nên luôn thông.
 *
 * <p>Chạy nền để SMTP/HTTP chậm không làm treo request (gửi OTP, đặt hàng...).
 * Fail-safe: lỗi gửi chỉ ghi log, không làm hỏng nghiệp vụ đã commit.
 */
@Component
@Slf4j
@RequiredArgsConstructor
public class AsyncEmailSender {

    private final JavaMailSender mailSender;
    private final GmailApiEmailSender gmailApiEmailSender;
    private final BrevoApiEmailSender brevoApiEmailSender;

    @Async
    public void send(MimeMessage message) {
        try {
            if (brevoApiEmailSender.isConfigured()) {
                brevoApiEmailSender.send(message);
                log.info("Đã gửi email qua Brevo API.");
            } else if (gmailApiEmailSender.isConfigured()) {
                gmailApiEmailSender.send(message);
                log.info("Đã gửi email qua Gmail API.");
            } else {
                mailSender.send(message);
                log.info("Đã gửi email qua SMTP.");
            }
        } catch (Exception ex) {
            log.warn("Gửi email nền thất bại: {}", ex.getMessage());
        }
    }
}
