package com.marinelink.products;

import java.util.UUID;

public record ProductImageResponse(
        UUID id,
        String imageUrl,
        String altText,
        int displayOrder) {

    public static ProductImageResponse from(ProductImage image) {
        return new ProductImageResponse(
                image.getPublicId(),
                image.getImageUrl(),
                image.getAltText(),
                image.getDisplayOrder());
    }
}
