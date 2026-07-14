package com.marinelink.admin;

import com.marinelink.common.AsyncEmailSender;
import com.marinelink.users.User;
import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

@Slf4j
@Service
@RequiredArgsConstructor
public class AdminUserNotificationService {

    private final JavaMailSender mailSender;
    private final AsyncEmailSender asyncEmailSender;

    @Value("${app.mail.from}")
    private String mailFrom = "no-reply@marinelink.local";

    @Value("${app.mail.from-name:MarineLink}")
    private String mailFromName = "MarineLink";

    public void sendAccountApprovedEmail(User user) {
        String toEmail = user.getEmail();
        if (toEmail == null || toEmail.isBlank()) {
            return;
        }

        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
            helper.setFrom(mailFrom, mailFromName);
            helper.setTo(toEmail);
            helper.setSubject("MarineLink - Tài khoản của bạn đã được duyệt");
            helper.setText(buildAccountApprovedHtml(user), true);
            asyncEmailSender.send(message);
        } catch (Exception ex) {
            log.warn("Cannot send account approval email to {}: {}", toEmail, ex.getMessage());
        }
    }

    private String buildAccountApprovedHtml(User user) {
        String fullName = escapeHtml(user.getFullName());
        String storeName = user.getStoreName() == null || user.getStoreName().isBlank()
                ? "Tài khoản MarineLink"
                : escapeHtml(user.getStoreName());
        return """
                <!DOCTYPE html>
                <html lang="vi">
                <head>
                  <meta charset="UTF-8">
                  <meta name="viewport" content="width=device-width, initial-scale=1.0">
                </head>
                <body style="margin:0;padding:0;background:#f4f8fb;font-family:Inter,Arial,sans-serif;">
                  <table width="100%%" cellpadding="0" cellspacing="0" style="background:#f4f8fb;padding:32px 0;">
                    <tr><td align="center">
                      <table width="560" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:14px;overflow:hidden;border:1px solid #e4eef5;">
                        <tr>
                          <td style="background:#006c67;padding:28px 36px;text-align:center;">
                            <h1 style="color:#ffffff;margin:0;font-size:26px;font-weight:800;">MarineLink</h1>
                            <p style="color:rgba(255,255,255,0.82);margin:6px 0 0;font-size:14px;">Thông báo tài khoản</p>
                          </td>
                        </tr>
                        <tr>
                          <td style="padding:34px 36px;">
                            <h2 style="color:#052449;font-size:21px;margin:0 0 12px;">Tài khoản của bạn đã được duyệt</h2>
                            <p style="color:#4a5160;font-size:15px;line-height:1.6;margin:0 0 20px;">
                              Xin chào %s,<br>
                              MarineLink đã duyệt tài khoản đăng ký của bạn. Bạn có thể đăng nhập và sử dụng các chức năng đặt hàng trong ứng dụng.
                            </p>
                            <div style="background:#eef8f7;border-radius:12px;padding:18px 20px;margin:0 0 20px;">
                              <p style="color:#4a5160;font-size:13px;margin:0 0 6px;">Thông tin tài khoản</p>
                              <p style="color:#006c67;font-size:20px;font-weight:800;margin:0;">%s</p>
                            </div>
                            <p style="color:#6b7280;font-size:13px;line-height:1.5;margin:0;">
                              Nếu cần hỗ trợ, vui lòng liên hệ đội ngũ MarineLink qua mục trò chuyện trong ứng dụng.
                            </p>
                          </td>
                        </tr>
                      </table>
                    </td></tr>
                  </table>
                </body>
                </html>
                """.formatted(fullName, storeName);
    }

    private String escapeHtml(String value) {
        if (value == null) {
            return "";
        }
        return value
                .replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
    }
}
