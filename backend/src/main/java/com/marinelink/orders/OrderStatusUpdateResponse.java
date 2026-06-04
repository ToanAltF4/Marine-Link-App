package com.marinelink.orders;

import java.util.UUID;

public record OrderStatusUpdateResponse(
        UUID id,
        OrderStatus status) {

    public static OrderStatusUpdateResponse from(Order order) {
        return new OrderStatusUpdateResponse(order.getPublicId(), order.getStatus());
    }
}
