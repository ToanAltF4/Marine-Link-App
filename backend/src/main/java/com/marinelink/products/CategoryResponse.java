package com.marinelink.products;

import java.util.UUID;

public record CategoryResponse(UUID id, String name) {

    public static CategoryResponse from(Category category) {
        return new CategoryResponse(category.getPublicId(), category.getName());
    }
}
