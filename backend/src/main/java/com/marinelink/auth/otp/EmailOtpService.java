package com.marinelink.auth.otp;

import com.marinelink.common.exception.BusinessException;
import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.Instant;
import java.time.temporal.ChronoUnit;

/**
 * Handles generation, storage, delivery, and validation of email OTPs.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class EmailOtpService {

    private static final SecureRandom SECURE_RANDOM = new SecureRandom();

    private final JavaMailSender mailSender;
    private final EmailOtpRepository emailOtpRepository;

    @Value("${app.mail.from}")
    private String mailFrom;

    @Value("${app.mail.from-name:MarineLink}")
    private String mailFromName;

    @Value("${app.mail.otp-expiry-minutes:10}")
    private int otpExpiryMinutes;

    /**
     * Generates a 6-digit OTP, persists it, and sends it to the given email address.
     * Any previous unused OTPs for this email are invalidated first.
     */
    @Transactional
    public void sendOtp(String email) {
        // Remove any existing OTPs for this email before issuing a new one
        emailOtpRepository.deleteByEmail(email);

        String otpCode = generateOtp();
        Instant expiresAt = Instant.now().plus(otpExpiryMinutes, ChronoUnit.MINUTES);

        EmailOtp otp = EmailOtp.builder()
                .email(email)
                .otpCode(otpCode)
                .expiresAt(expiresAt)
                .build();
        emailOtpRepository.save(otp);

        sendOtpEmail(email, otpCode);
        log.info("OTP sent to {}", email);
    }

    /**
     * Validates the provided OTP code for the given email.
     *
     * @throws BusinessException if the OTP is invalid, expired, or already used.
     */
    @Transactional
    public void verifyOtp(String email, String otpCode) {
        EmailOtp otp = emailOtpRepository
                .findTopByEmailAndUsedFalseOrderByCreatedAtDesc(email)
                .orElseThrow(() -> new BusinessException(
                        "Mã OTP không hợp lệ hoặc đã hết hạn", HttpStatus.BAD_REQUEST));

        if (otp.getExpiresAt().isBefore(Instant.now())) {
            throw new BusinessException("Mã OTP đã hết hạn", HttpStatus.BAD_REQUEST);
        }

        if (!otp.getOtpCode().equals(otpCode)) {
            throw new BusinessException("Mã OTP không chính xác", HttpStatus.BAD_REQUEST);
        }

        otp.setUsed(true);
        emailOtpRepository.save(otp);
    }

    // ── Private helpers ────────────────────────────────────────────────────────

    private String generateOtp() {
        int code = 100_000 + SECURE_RANDOM.nextInt(900_000);
        return String.valueOf(code);
    }

    private void sendOtpEmail(String toEmail, String otpCode) {
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
            helper.setFrom(mailFrom, mailFromName);
            helper.setTo(toEmail);
            helper.setSubject("Xác thực email MarineLink — Mã OTP của bạn");
            helper.setText(buildEmailHtml(otpCode), true);
            mailSender.send(message);
        } catch (Exception e) {
            log.error("Failed to send OTP email to {}: {}", toEmail, e.getMessage());
            throw new BusinessException(
                    "Không thể gửi email xác thực. Vui lòng thử lại sau.",
                    HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    private String buildEmailHtml(String otpCode) {
        return """
                <!DOCTYPE html>
                <html lang="vi">
                <head>
                  <meta charset="UTF-8">
                  <meta name="viewport" content="width=device-width, initial-scale=1.0">
                </head>
                <body style="margin:0;padding:0;background:#f0f4ff;font-family:Inter,Arial,sans-serif;">
                  <table width="100%%" cellpadding="0" cellspacing="0" style="background:#f0f4ff;padding:40px 0;">
                    <tr><td align="center">
                      <table width="560" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(5,36,73,0.10);">
                        <!-- Header -->
                        <tr>
                          <td style="background:linear-gradient(135deg,#0B3D91 0%%,#1565C0 100%%);padding:32px 40px;text-align:center;">
                            <h1 style="color:#ffffff;margin:0;font-size:28px;font-weight:800;letter-spacing:-0.5px;">🐟 MarineLink</h1>
                            <p style="color:rgba(255,255,255,0.8);margin:6px 0 0;font-size:14px;">Nền tảng thương mại hải sản B2B</p>
                          </td>
                        </tr>
                        <!-- Body -->
                        <tr>
                          <td style="padding:40px;">
                            <h2 style="color:#052449;font-size:22px;font-weight:700;margin:0 0 12px;">Xác thực địa chỉ email</h2>
                            <p style="color:#4A5160;font-size:15px;line-height:1.6;margin:0 0 28px;">
                              Cảm ơn bạn đã đăng ký tài khoản MarineLink! Nhập mã OTP dưới đây để xác thực email của bạn.
                              Mã có hiệu lực trong <strong>%d phút</strong>.
                            </p>
                            <!-- OTP Box -->
                            <div style="background:#f0f4ff;border:2px dashed #1565C0;border-radius:12px;padding:24px;text-align:center;margin-bottom:28px;">
                              <p style="color:#4A5160;font-size:13px;margin:0 0 8px;text-transform:uppercase;letter-spacing:1px;font-weight:600;">Mã xác thực của bạn</p>
                              <span style="font-size:42px;font-weight:900;letter-spacing:10px;color:#0B3D91;display:block;">%s</span>
                            </div>
                            <p style="color:#9098A9;font-size:13px;line-height:1.5;margin:0;">
                              Nếu bạn không thực hiện yêu cầu này, hãy bỏ qua email này.
                              Tài khoản của bạn sẽ không bị ảnh hưởng.
                            </p>
                          </td>
                        </tr>
                        <!-- Footer -->
                        <tr>
                          <td style="background:#f8faff;padding:20px 40px;text-align:center;border-top:1px solid #e8edf7;">
                            <p style="color:#9098A9;font-size:12px;margin:0;">© 2025 MarineLink. Tất cả quyền được bảo lưu.</p>
                          </td>
                        </tr>
                      </table>
                    </td></tr>
                  </table>
                </body>
                </html>
                """.formatted(otpExpiryMinutes, otpCode);
    }
}
