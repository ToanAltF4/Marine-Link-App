package com.marinelink.auth;

public record EmailAvailabilityResponse(
        boolean available,
        String message
) {
}
