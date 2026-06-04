package com.marinelink.orders;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public record OrderListItemResponse(
        UUID id,
        String orderCode,
        OrderStatus status,
        BigDecimal totalAmount,
        Instant createdAt) {

    public static OrderListItemResponse from(Order order) {
        return new OrderListItemResponse(
                order.getPublicId(),
                order.getOrderCode(),
                order.getStatus(),
                order.getTotalAmount(),
                order.getCreatedAt());
    }
}
