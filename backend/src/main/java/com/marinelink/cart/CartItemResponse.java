package com.marinelink.cart;

import com.marinelink.products.PriceTierResponse;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

public record CartItemResponse(
        UUID productId,
        String productName,
        String productImageUrl,
        String unit,
        int quantity,
        boolean selected,
        UUID selectedPriceTierId,
        BigDecimal baseUnitPrice,
        BigDecimal unitPrice,
        BigDecimal lineTotal,
        int minOrderQuantity,
        int stockQuantity,
        List<PriceTierResponse> priceTiers) {

    public static CartItemResponse from(CartItem item, BigDecimal unitPrice) {
        return new CartItemResponse(
                item.getProduct().getPublicId(),
                item.getProduct().getName(),
                item.getProduct().getImageUrl(),
                item.getProduct().getUnit(),
                item.getQuantity(),
                item.isSelected(),
                item.getPriceTier() != null ? item.getPriceTier().getPublicId() : null,
                item.getProduct().getBasePrice(),
                unitPrice,
                unitPrice.multiply(BigDecimal.valueOf(item.getQuantity())),
                item.getProduct().getMinOrderQuantity(),
                item.getProduct().getStockQuantity(),
                item.getProduct().getPriceTiers()
                        .stream()
                        .map(PriceTierResponse::from)
                        .toList());
    }
}
