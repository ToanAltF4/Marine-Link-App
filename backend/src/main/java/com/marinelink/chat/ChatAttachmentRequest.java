package com.marinelink.chat;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Positive;

public record ChatAttachmentRequest(
        @NotBlank String storageBucket,
        @NotBlank String storagePath,
        @NotBlank String fileName,
        @NotBlank String mimeType,
        @Positive Long fileSizeBytes
) {}
