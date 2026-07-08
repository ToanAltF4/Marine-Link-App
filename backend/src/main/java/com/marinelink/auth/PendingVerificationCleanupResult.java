package com.marinelink.auth;

public record PendingVerificationCleanupResult(
        int pendingAccountsDeleted,
        int expiredOtpsDeleted) {
}
