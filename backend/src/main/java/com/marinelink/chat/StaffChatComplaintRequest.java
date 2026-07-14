package com.marinelink.chat;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public record StaffChatComplaintRequest(
        @NotBlank @Size(max = 200) String title,
        @NotBlank @Size(max = 2000) String description,
        UUID messageId
) {
}
