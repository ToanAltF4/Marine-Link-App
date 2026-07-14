package com.marinelink.auth;

import com.marinelink.auth.otp.EmailOtpRepository;
import com.marinelink.users.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class PendingVerificationCleanupServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private EmailOtpRepository emailOtpRepository;

    @Test
    void cleanupHardDeletesPendingVerificationUsersAndDeletesExpiredOtps() {
        Instant now = Instant.parse("2026-07-02T12:00:00Z");
        Clock clock = Clock.fixed(now, ZoneOffset.UTC);
        PendingVerificationCleanupService service =
                new PendingVerificationCleanupService(userRepository, emailOtpRepository, clock, 24);
        Instant cutoff = Instant.parse("2026-07-01T12:00:00Z");

        when(userRepository.deletePendingVerificationCreatedBefore(cutoff)).thenReturn(3);
        when(emailOtpRepository.deleteExpiredBefore(now)).thenReturn(5);

        PendingVerificationCleanupResult result = service.cleanupExpiredAuthVerificationData();

        assertThat(result.pendingAccountsDeleted()).isEqualTo(3);
        assertThat(result.expiredOtpsDeleted()).isEqualTo(5);
        verify(userRepository).deletePendingVerificationCreatedBefore(cutoff);
        verify(emailOtpRepository).deleteExpiredBefore(now);
    }
}
