package com.marinelink.chat;

import java.time.Instant;
import java.util.UUID;

/**
 * One row in the buyer's chat history list. {@code title} is the room's first
 * message content (fallback text when the room has no messages yet).
 */
public record ChatRoomSummaryResponse(
        UUID roomId,
        String title,
        Instant lastMessageAt,
        boolean isClosed
) {
}
