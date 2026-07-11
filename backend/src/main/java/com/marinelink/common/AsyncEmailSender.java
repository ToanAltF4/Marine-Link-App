package com.marinelink.common;

import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

/**
 * Gửi email ở luồng nền (@Async) để không chặn request nghiệp vụ.
 *
 * <p>SMTP có thể mất vài giây (bắt tay + gửi); nếu gọi đồng bộ trong request
 * tạo đơn thì client dễ timeout dù đơn đã lưu. Build message vẫn làm đồng bộ
 * (đọc dữ liệu đã nạp), chỉ bước gửi mạng chạy nền. Fail-safe: nuốt lỗi.
 */
@Component
@Slf4j
@RequiredArgsConstructor
public class AsyncEmailSender {

    private final JavaMailSender mailSender;

    @Async
    public void send(MimeMessage message) {
        try {
            mailSender.send(message);
        } catch (Exception ex) {
            log.warn("Gửi email nền thất bại: {}", ex.getMessage());
        }
    }
}
