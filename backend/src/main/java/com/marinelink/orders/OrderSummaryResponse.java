package com.marinelink.orders;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public record OrderSummaryResponse(
        UUID id,
        String orderCode,
        OrderStatus status,
        PaymentMethodCode paymentMethod,
        PaymentStatus paymentStatus,
        BigDecimal subtotalAmount,
        BigDecimal shippingFee,
        BigDecimal discountAmount,
        BigDecimal totalAmount,
        Instant createdAt) {

    public static OrderSummaryResponse from(Order order) {
        return new OrderSummaryResponse(
                order.getPublicId(),
                order.getOrderCode(),
                order.getStatus(),
                order.getPaymentMethod().getCode(),
                order.getPaymentStatus(),
                order.getSubtotalAmount(),
                order.getShippingFee(),
                order.getDiscountAmount(),
                order.getTotalAmount(),
                order.getCreatedAt());
    }
}
