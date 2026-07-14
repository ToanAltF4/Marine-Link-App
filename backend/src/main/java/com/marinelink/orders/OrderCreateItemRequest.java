package com.marinelink.orders;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record OrderCreateItemRequest(
        @NotNull UUID productId,
        @Min(1) int quantity) {
}
