package com.marinelink.cart;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record CartSyncItemRequest(
        @NotNull UUID productId,
        @Min(1) int quantity,
        boolean selected) {
}
