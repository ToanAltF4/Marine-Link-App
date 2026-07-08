package com.marinelink.auth;

import com.marinelink.auth.otp.EmailOtpRepository;
import com.marinelink.users.UserRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.Instant;
import java.time.temporal.ChronoUnit;

@Slf4j
@Service
public class PendingVerificationCleanupService {

    private final UserRepository userRepository;
    private final EmailOtpRepository emailOtpRepository;
    private final Clock clock;
    private final long retentionHours;

    public PendingVerificationCleanupService(
            UserRepository userRepository,
            EmailOtpRepository emailOtpRepository,
            Clock clock,
            @Value("${app.auth.pending-verification-retention-hours:24}") long retentionHours) {
        this.userRepository = userRepository;
        this.emailOtpRepository = emailOtpRepository;
        this.clock = clock;
        this.retentionHours = retentionHours;
    }

    @Scheduled(fixedDelayString = "${app.auth.pending-verification-cleanup-delay-ms:3600000}")
    @Transactional
    public PendingVerificationCleanupResult cleanupExpiredAuthVerificationData() {
        Instant now = Instant.now(clock);
        Instant accountCutoff = now.minus(retentionHours, ChronoUnit.HOURS);
        int pendingAccountsDeleted = userRepository.deletePendingVerificationCreatedBefore(accountCutoff);
        int expiredOtpsDeleted = emailOtpRepository.deleteExpiredBefore(now);

        if (pendingAccountsDeleted > 0 || expiredOtpsDeleted > 0) {
            log.info(
                    "Cleaned expired auth verification data: pendingAccountsDeleted={}, expiredOtpsDeleted={}",
                    pendingAccountsDeleted,
                    expiredOtpsDeleted);
        }
        return new PendingVerificationCleanupResult(pendingAccountsDeleted, expiredOtpsDeleted);
    }
}
