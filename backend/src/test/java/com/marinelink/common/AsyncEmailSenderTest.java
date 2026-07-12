package com.marinelink.common;

import jakarta.mail.Session;
import jakarta.mail.internet.MimeMessage;
import org.junit.jupiter.api.Test;
import org.springframework.mail.javamail.JavaMailSender;

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
    private final AsyncEmailSender sender = new AsyncEmailSender(mailSender, gmailApi);

    private MimeMessage message() {
        return new MimeMessage(Session.getInstance(new Properties()));
    }

    @Test
    void usesSmtpWhenGmailApiNotConfigured() throws Exception {
        when(gmailApi.isConfigured()).thenReturn(false);
        MimeMessage message = message();

        sender.send(message);

        verify(mailSender).send(message);
        verify(gmailApi, never()).send(any());
    }

    @Test
    void usesGmailApiWhenConfigured() throws Exception {
        when(gmailApi.isConfigured()).thenReturn(true);
        MimeMessage message = message();

        sender.send(message);

        verify(gmailApi).send(message);
        verify(mailSender, never()).send(any(MimeMessage.class));
    }

    @Test
    void swallowsSendFailureSoBusinessFlowIsNotBroken() throws Exception {
        when(gmailApi.isConfigured()).thenReturn(true);
        doThrow(new IllegalStateException("boom")).when(gmailApi).send(any());

        assertThatCode(() -> sender.send(message())).doesNotThrowAnyException();
    }

    @Test
    void gmailApiIsConfiguredOnlyWhenAllCredentialsPresent() {
        assertThat(new GmailApiEmailSender("id", "secret", "refresh", null).isConfigured())
                .isTrue();
        assertThat(new GmailApiEmailSender("", "secret", "refresh", null).isConfigured())
                .isFalse();
        assertThat(new GmailApiEmailSender("id", "secret", "  ", null).isConfigured())
                .isFalse();
    }
}
