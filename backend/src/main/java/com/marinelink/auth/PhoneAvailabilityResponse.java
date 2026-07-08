package com.marinelink.auth;

public record PhoneAvailabilityResponse(
        boolean available,
        String message
) {
}
