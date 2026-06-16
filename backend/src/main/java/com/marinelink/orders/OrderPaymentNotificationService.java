package com.marinelink.orders;

import com.marinelink.notifications.NotificationService;
import com.marinelink.notifications.NotificationType;
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
public class OrderPaymentNotificationService {

    private final NotificationService notificationService;
    private final JavaMailSender mailSender;

    @Value("${app.mail.from}")
    private String mailFrom = "no-reply@marinelink.local";

    @Value("${app.mail.from-name:MarineLink}")
    private String mailFromName = "MarineLink";

    public void notifyOrderWaitingForApproval(Order order) {
        String body = "Đơn hàng " + order.getOrderCode()
                + " đã được tạo và sẽ được duyệt trong thời gian sớm nhất.";
        notifyWaitingForApproval(order, body, false);
    }

    public void notifyPaidOrderWaitingForApproval(Order order) {
        String body = "Đơn hàng " + order.getOrderCode()
                + " đã ghi nhận thanh toán và sẽ được duyệt trong thời gian sớm nhất.";
        notifyWaitingForApproval(order, body, true);
    }

    private void notifyWaitingForApproval(Order order, String body, boolean paymentRecorded) {
        notificationService.createNotification(
                order.getUser(),
                NotificationType.ORDER,
                "Đơn hàng đang chờ duyệt",
                body,
                order);
        sendOrderWaitingForApprovalEmail(order, paymentRecorded);
    }

    private void sendOrderWaitingForApprovalEmail(Order order, boolean paymentRecorded) {
        String toEmail = order.getUser().getEmail();
        if (toEmail == null || toEmail.isBlank()) {
            return;
        }
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
            helper.setFrom(mailFrom, mailFromName);
            helper.setTo(toEmail);
            helper.setSubject("MarineLink - Đơn hàng " + order.getOrderCode() + " đang chờ duyệt");
            helper.setText(buildEmailHtml(order, paymentRecorded), true);
            mailSender.send(message);
        } catch (Exception ex) {
            log.warn("Cannot send order approval email for {} to {}: {}",
                    order.getOrderCode(), toEmail, ex.getMessage());
        }
    }

    private String buildEmailHtml(Order order, boolean paymentRecorded) {
        String intro = paymentRecorded
                ? "MarineLink đã ghi nhận thanh toán cho đơn hàng <strong>%s</strong>."
                : "MarineLink đã nhận đơn hàng <strong>%s</strong> của bạn.";
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
                            <p style="color:rgba(255,255,255,0.82);margin:6px 0 0;font-size:14px;">Thông báo đơn hàng</p>
                          </td>
                        </tr>
                        <tr>
                          <td style="padding:34px 36px;">
                            <h2 style="color:#052449;font-size:21px;margin:0 0 12px;">Đơn hàng của bạn sẽ được duyệt trong thời gian sớm nhất</h2>
                            <p style="color:#4a5160;font-size:15px;line-height:1.6;margin:0 0 20px;">
                              %s
                              Nhân viên sẽ kiểm tra và duyệt đơn trong thời gian sớm nhất.
                            </p>
                            <div style="background:#eef8f7;border-radius:12px;padding:18px 20px;margin:0 0 20px;">
                              <p style="color:#4a5160;font-size:13px;margin:0 0 6px;">Mã đơn hàng</p>
                              <p style="color:#006c67;font-size:22px;font-weight:800;margin:0;">%s</p>
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
                """.formatted(intro.formatted(order.getOrderCode()), order.getOrderCode());
    }
}
