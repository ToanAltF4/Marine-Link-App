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
 * <p>Chọn đường gửi theo cấu hình:
 * <ul>
 *   <li><b>Gmail API (HTTPS)</b> nếu có client-id/secret/refresh-token — dùng cho
 *       môi trường deploy (Render chặn cổng SMTP 25/465/587 nên SMTP không đi được).</li>
 *   <li><b>SMTP</b> nếu chưa cấu hình Gmail API — tiện cho chạy local.</li>
 * </ul>
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

    @Async
    public void send(MimeMessage message) {
        try {
            if (gmailApiEmailSender.isConfigured()) {
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
