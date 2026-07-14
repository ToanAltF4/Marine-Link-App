package com.marinelink.users;

/**
 * User account status as defined in the DB design.
 */
public enum UserStatus {
    PENDING_VERIFICATION,
    PENDING_APPROVAL,
    ACTIVE,
    DISABLED
}
