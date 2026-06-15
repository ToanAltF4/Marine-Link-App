package com.marinelink.orders;

public record VnpayPaymentResultResponse(
        String txnRef,
        String orderCode,
        PaymentStatus paymentStatus,
        String responseCode,
        String transactionStatus,
        String message) {
}
