package com.marinelink.common.security;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.UUID;

/**
 * Utility to retrieve the currently authenticated user's public UUID from
 * the Spring Security context, as set by {@link JwtAuthenticationFilter}.
 */
public final class CurrentUser {

    private CurrentUser() {}

    /**
     * Returns the authenticated user's {@code public_id} UUID.
     *
     * @throws IllegalStateException if called outside an authenticated context
     */
    public static UUID publicId() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated()) {
            throw new IllegalStateException("No authenticated user in security context");
        }
        return UUID.fromString((String) auth.getPrincipal());
    }

    public static boolean hasRole(String role) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) return false;
        return auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_" + role));
    }
}
