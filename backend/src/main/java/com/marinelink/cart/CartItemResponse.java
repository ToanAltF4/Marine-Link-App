package com.marinelink.cart;

import java.math.BigDecimal;
import java.util.UUID;

public record CartItemResponse(
        UUID productId,
        String productName,
        String productImageUrl,
        String unit,
        int quantity,
        boolean selected,
        UUID selectedPriceTierId,
        BigDecimal unitPrice,
        BigDecimal lineTotal) {

    public static CartItemResponse from(CartItem item, BigDecimal unitPrice) {
        return new CartItemResponse(
                item.getProduct().getPublicId(),
                item.getProduct().getName(),
                item.getProduct().getImageUrl(),
                item.getProduct().getUnit(),
                item.getQuantity(),
                item.isSelected(),
                item.getPriceTier() != null ? item.getPriceTier().getPublicId() : null,
                unitPrice,
                unitPrice.multiply(BigDecimal.valueOf(item.getQuantity())));
    }
}
