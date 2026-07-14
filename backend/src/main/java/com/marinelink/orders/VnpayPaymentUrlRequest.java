package com.marinelink.orders;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public record VnpayPaymentUrlRequest(
        @NotNull UUID orderId,
        @Size(max = 20) String bankCode) {
}
