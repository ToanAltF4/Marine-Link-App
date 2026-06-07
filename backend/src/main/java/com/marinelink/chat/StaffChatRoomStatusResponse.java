package com.marinelink.chat;

import java.util.UUID;

public record StaffChatRoomStatusResponse(
        UUID roomId,
        boolean isClosed
) {
    static StaffChatRoomStatusResponse from(ChatRoom room) {
        return new StaffChatRoomStatusResponse(room.getPublicId(), room.isClosed());
    }
}
