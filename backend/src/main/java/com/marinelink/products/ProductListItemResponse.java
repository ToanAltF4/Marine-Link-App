package com.marinelink.products;

import java.math.BigDecimal;
import java.util.UUID;

public record ProductListItemResponse(
        UUID id,
        String name,
        String slug,
        String origin,
        String imageUrl,
        BigDecimal basePrice,
        String unit,
        int minOrderQuantity,
        int stockQuantity,
        ProductStatus status,
        boolean isFeatured,
        CategoryResponse category) {

    public static ProductListItemResponse from(Product product) {
        return new ProductListItemResponse(
                product.getPublicId(),
                product.getName(),
                product.getSlug(),
                product.getOrigin(),
                product.getImageUrl(),
                product.getBasePrice(),
                product.getUnit(),
                product.getMinOrderQuantity(),
                product.getStockQuantity(),
                product.getStatus(),
                product.isFeatured(),
                CategoryResponse.from(product.getCategory()));
    }
}
