package com.marinelink.cart;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;

import java.util.List;

public record CartSyncRequest(
        @NotNull List<@Valid CartSyncItemRequest> items) {
}
