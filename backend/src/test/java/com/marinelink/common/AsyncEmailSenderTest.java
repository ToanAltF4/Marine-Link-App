package com.marinelink.common;

import jakarta.mail.Session;
import jakarta.mail.internet.MimeMessage;
import org.junit.jupiter.api.Test;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;

import java.util.Properties;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class AsyncEmailSenderTest {

    private final JavaMailSender mailSender = mock(JavaMailSender.class);
    private final GmailApiEmailSender gmailApi = mock(GmailApiEmailSender.class);
    private final BrevoApiEmailSender brevoApi = mock(BrevoApiEmailSender.class);
    private final AsyncEmailSender sender =
            new AsyncEmailSender(mailSender, gmailApi, brevoApi);

    private MimeMessage message() {
        return new MimeMessage(Session.getInstance(new Properties()));
    }

    @Test
    void usesSmtpWhenNoApiConfigured() throws Exception {
        when(brevoApi.isConfigured()).thenReturn(false);
        when(gmailApi.isConfigured()).thenReturn(false);
        MimeMessage message = message();

        sender.send(message);

        verify(mailSender).send(message);
        verify(brevoApi, never()).send(any());
        verify(gmailApi, never()).send(any());
    }

    @Test
    void prefersBrevoApiWhenConfigured() throws Exception {
        when(brevoApi.isConfigured()).thenReturn(true);
        MimeMessage message = message();

        sender.send(message);

        verify(brevoApi).send(message);
        verify(gmailApi, never()).send(any());
        verify(mailSender, never()).send(any(MimeMessage.class));
    }

    @Test
    void fallsBackToGmailApiWhenBrevoNotConfigured() throws Exception {
        when(brevoApi.isConfigured()).thenReturn(false);
        when(gmailApi.isConfigured()).thenReturn(true);
        MimeMessage message = message();

        sender.send(message);

        verify(gmailApi).send(message);
        verify(mailSender, never()).send(any(MimeMessage.class));
    }

    @Test
    void swallowsSendFailureSoBusinessFlowIsNotBroken() throws Exception {
        when(brevoApi.isConfigured()).thenReturn(true);
        doThrow(new IllegalStateException("boom")).when(brevoApi).send(any());

        assertThatCode(() -> sender.send(message())).doesNotThrowAnyException();
    }

    @Test
    void brevoIsConfiguredOnlyWithApiKeyAndSender() {
        assertThat(new BrevoApiEmailSender("key", "from@x.com", "MarineLink", null).isConfigured())
                .isTrue();
        assertThat(new BrevoApiEmailSender("", "from@x.com", "MarineLink", null).isConfigured())
                .isFalse();
        assertThat(new BrevoApiEmailSender("key", "  ", "MarineLink", null).isConfigured())
                .isFalse();
    }

    @Test
    void gmailApiIsConfiguredOnlyWhenAllCredentialsPresent() {
        assertThat(new GmailApiEmailSender("id", "secret", "refresh", null).isConfigured())
                .isTrue();
        assertThat(new GmailApiEmailSender("", "secret", "refresh", null).isConfigured())
                .isFalse();
    }

    @Test
    void extractsHtmlBodyFromMimeMessageForBrevoPayload() throws Exception {
        MimeMessage message = message();
        MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
        helper.setTo("daily-a@example.com");
        helper.setSubject("Mã OTP");
        helper.setText("<h1>Mã của bạn: 123456</h1>", true);

        assertThat(BrevoApiEmailSender.htmlContent(message))
                .contains("Mã của bạn: 123456");
    }
}
