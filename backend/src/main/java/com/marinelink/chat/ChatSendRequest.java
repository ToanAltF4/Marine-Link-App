package com.marinelink.chat;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.List;
import java.util.UUID;

public record ChatSendRequest(
        @NotNull UUID roomId,
        @NotBlank @Size(max = 4000) String content,
        List<@Valid ChatAttachmentRequest> attachments
) {}
