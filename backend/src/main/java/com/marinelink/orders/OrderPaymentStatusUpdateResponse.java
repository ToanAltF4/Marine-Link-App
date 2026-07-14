package com.marinelink.orders;

import java.util.UUID;

public record OrderPaymentStatusUpdateResponse(
        UUID id,
        PaymentStatus paymentStatus) {

    public static OrderPaymentStatusUpdateResponse from(Order order) {
        return new OrderPaymentStatusUpdateResponse(order.getPublicId(), order.getPaymentStatus());
    }
}
