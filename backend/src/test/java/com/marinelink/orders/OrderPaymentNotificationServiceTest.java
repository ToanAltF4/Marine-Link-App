package com.marinelink.orders;

import com.marinelink.notifications.NotificationService;
import com.marinelink.users.User;
import jakarta.mail.Message;
import jakarta.mail.Session;
import jakarta.mail.internet.MimeMessage;
import org.junit.jupiter.api.Test;
import org.springframework.mail.javamail.JavaMailSender;

import java.math.BigDecimal;
import java.util.Properties;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class OrderPaymentNotificationServiceTest {

    private final NotificationService notificationService = mock(NotificationService.class);
    private final JavaMailSender mailSender = mock(JavaMailSender.class);
    private final OrderPaymentNotificationService service =
            new OrderPaymentNotificationService(notificationService, mailSender);

    @Test
    void notifiesAndEmailsUserThatPaidOrderIsWaitingForApproval() {
        User user = User.builder()
                .publicId(UUID.randomUUID())
                .fullName("Nguyen Van A")
                .email("daily-a@example.com")
                .build();
        Order order = Order.builder()
                .publicId(UUID.randomUUID())
                .orderCode("ML-20260615-0001")
                .user(user)
                .totalAmount(new BigDecimal("850000"))
                .build();
        when(mailSender.createMimeMessage())
                .thenReturn(new MimeMessage(Session.getInstance(new Properties())));

        service.notifyPaidOrderWaitingForApproval(order);

        verify(notificationService).createNotification(
                eq(user),
                any(),
                eq("Đơn hàng đang chờ duyệt"),
                eq("Đơn hàng ML-20260615-0001 đã ghi nhận thanh toán và sẽ được duyệt trong thời gian sớm nhất."),
                eq(order));
        verify(mailSender).send(any(MimeMessage.class));
    }

    @Test
    void emailsUserThatOrderHasBeenApproved() throws Exception {
        User user = User.builder()
                .publicId(UUID.randomUUID())
                .fullName("Nguyen Van A")
                .email("daily-a@example.com")
                .build();
        Order order = Order.builder()
                .publicId(UUID.randomUUID())
                .orderCode("ML-20260615-0001")
                .user(user)
                .totalAmount(new BigDecimal("850000"))
                .build();
        MimeMessage message = new MimeMessage(Session.getInstance(new Properties()));
        when(mailSender.createMimeMessage()).thenReturn(message);

        service.sendOrderApprovedEmail(order);

        assertThat(message.getSubject()).isEqualTo("MarineLink - Đơn hàng ML-20260615-0001 đã được duyệt");
        assertThat(message.getRecipients(Message.RecipientType.TO)[0].toString())
                .isEqualTo("daily-a@example.com");
        verify(mailSender).send(message);
    }
}
