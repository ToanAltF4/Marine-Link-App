package com.marinelink.orders;

import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record VnpayPaymentCancelRequest(@NotNull UUID orderId) {
}
