package com.marinelink.notifications.dto;

import java.time.Instant;
import java.util.UUID;

/**
 * One row in the admin/staff "sent notifications" history — one broadcast,
 * summarised from its fanned-out per-user rows.
 */
public record BroadcastSummaryDTO(
        UUID broadcastId,
        String title,
        String body,
        UUID createdBy,
        Instant createdAt,
        long recipientCount
) {
}
