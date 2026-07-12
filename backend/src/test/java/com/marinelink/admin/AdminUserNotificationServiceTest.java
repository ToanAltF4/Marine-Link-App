package com.marinelink.admin;

import com.marinelink.users.User;
import jakarta.mail.Message;
import jakarta.mail.Session;
import jakarta.mail.internet.MimeMessage;
import org.junit.jupiter.api.Test;
import org.springframework.mail.javamail.JavaMailSender;

import java.util.Properties;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class AdminUserNotificationServiceTest {

    private final JavaMailSender mailSender = mock(JavaMailSender.class);
    private final com.marinelink.common.AsyncEmailSender asyncEmailSender =
            mock(com.marinelink.common.AsyncEmailSender.class);
    private final AdminUserNotificationService service =
            new AdminUserNotificationService(mailSender, asyncEmailSender);

    @Test
    void emailsUserThatAccountHasBeenApproved() throws Exception {
        User user = User.builder()
                .publicId(UUID.randomUUID())
                .fullName("Đại lý A")
                .email("daily-a@example.com")
                .storeName("Đại lý hải sản A")
                .build();
        MimeMessage message = new MimeMessage(Session.getInstance(new Properties()));
        when(mailSender.createMimeMessage()).thenReturn(message);

        service.sendAccountApprovedEmail(user);

        assertThat(message.getSubject()).isEqualTo("MarineLink - Tài khoản của bạn đã được duyệt");
        assertThat(message.getRecipients(Message.RecipientType.TO)[0].toString())
                .isEqualTo("daily-a@example.com");
        verify(asyncEmailSender).send(message);
    }
}
