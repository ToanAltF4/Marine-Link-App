package com.marinelink.chat;

import jakarta.validation.constraints.NotNull;

public record StaffChatRoomStatusUpdateRequest(
        @NotNull Boolean isClosed
) {
}
