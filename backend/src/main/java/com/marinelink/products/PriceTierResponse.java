package com.marinelink.products;

import java.math.BigDecimal;
import java.util.UUID;

public record PriceTierResponse(
        UUID id,
        int minQuantity,
        Integer maxQuantity,
        BigDecimal unitPrice) {

    public static PriceTierResponse from(PriceTier tier) {
        return new PriceTierResponse(
                tier.getPublicId(),
                tier.getMinQuantity(),
                tier.getMaxQuantity(),
                tier.getUnitPrice());
    }
}
