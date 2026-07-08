package com.marinelink.cart;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record CartItemCreateRequest(
        @NotNull UUID productId,
        @Min(1) int quantity,
        Boolean selected) {
}
