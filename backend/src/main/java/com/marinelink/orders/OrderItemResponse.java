package com.marinelink.orders;

import java.math.BigDecimal;
import java.util.UUID;

public record OrderItemResponse(
        UUID productId,
        String productNameSnapshot,
        String productUnitSnapshot,
        BigDecimal unitPrice,
        int quantity,
        BigDecimal lineTotal) {

    public static OrderItemResponse from(OrderItem item) {
        return new OrderItemResponse(
                item.getProduct().getPublicId(),
                item.getProductNameSnapshot(),
                item.getProductUnitSnapshot(),
                item.getUnitPrice(),
                item.getQuantity(),
                item.getLineTotal());
    }
}
