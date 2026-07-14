package com.marinelink.chat;

import com.marinelink.orders.Order;
import com.marinelink.products.Product;

import java.math.BigDecimal;
import java.util.UUID;

public record StaffChatContextResponse(
        UUID orderId,
        String orderCode,
        String orderStatus,
        BigDecimal orderTotalAmount,
        UUID productId,
        String productName,
        String productImageUrl
) {
    static StaffChatContextResponse from(ChatRoom room) {
        Order order = room.getRelatedOrder();
        Product product = room.getRelatedProduct();
        if (order == null && product == null) {
            return null;
        }
        return new StaffChatContextResponse(
                order == null ? null : order.getPublicId(),
                order == null ? null : order.getOrderCode(),
                order == null ? null : order.getStatus().name(),
                order == null ? null : order.getTotalAmount(),
                product == null ? null : product.getPublicId(),
                product == null ? null : product.getName(),
                product == null ? null : product.getImageUrl());
    }
}
