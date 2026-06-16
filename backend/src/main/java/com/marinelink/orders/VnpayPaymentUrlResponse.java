package com.marinelink.orders;

import java.util.UUID;

public record VnpayPaymentUrlResponse(
        UUID orderId,
        String orderCode,
        String txnRef,
        String paymentUrl) {
}
