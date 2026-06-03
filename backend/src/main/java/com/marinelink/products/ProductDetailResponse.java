package com.marinelink.products;

import java.math.BigDecimal;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;

public record ProductDetailResponse(
        UUID id,
        String name,
        String slug,
        String description,
        String origin,
        String imageUrl,
        BigDecimal basePrice,
        String unit,
        int minOrderQuantity,
        int stockQuantity,
        ProductStatus status,
        boolean isFeatured,
        CategoryResponse category,
        List<ProductImageResponse> images,
        List<PriceTierResponse> priceTiers) {

    public static ProductDetailResponse from(Product product) {
        List<ProductImageResponse> images = product.getImages().stream()
                .sorted(Comparator.comparingInt(ProductImage::getDisplayOrder))
                .map(ProductImageResponse::from)
                .toList();
        List<PriceTierResponse> priceTiers = product.getPriceTiers().stream()
                .sorted(Comparator.comparingInt(PriceTier::getMinQuantity))
                .map(PriceTierResponse::from)
                .toList();

        return new ProductDetailResponse(
                product.getPublicId(),
                product.getName(),
                product.getSlug(),
                product.getDescription(),
                product.getOrigin(),
                product.getImageUrl(),
                product.getBasePrice(),
                product.getUnit(),
                product.getMinOrderQuantity(),
                product.getStockQuantity(),
                product.getStatus(),
                product.isFeatured(),
                CategoryResponse.from(product.getCategory()),
                images,
                priceTiers);
    }
}
