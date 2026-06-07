package com.marinelink.chat;

import java.util.List;
import java.util.UUID;

public record ChatThreadResponse(
        UUID roomId,
        boolean isClosed,
        List<ChatMessageResponse> messages
) {}
