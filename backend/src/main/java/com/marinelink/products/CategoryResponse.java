package com.marinelink.products;

import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.UUID;

public record CategoryResponse(
        UUID id,
        String name,
        UUID parentId,
        String parentName,
        List<CategoryResponse> children) {

    public CategoryResponse(UUID id, String name) {
        this(id, name, null, null, List.of());
    }

    public static CategoryResponse from(Category category) {
        Category parent = category.getParent();
        return new CategoryResponse(
                category.getPublicId(),
                category.getName(),
                parent == null ? null : parent.getPublicId(),
                parent == null ? null : parent.getName(),
                List.of());
    }

    public static CategoryResponse treeFrom(Category category, Map<Long, List<Category>> childrenByParentId) {
        List<CategoryResponse> childResponses = childrenByParentId
                .getOrDefault(category.getId(), List.of())
                .stream()
                .filter(Category::isActive)
                .sorted(Comparator
                        .comparingInt(Category::getDisplayOrder)
                        .thenComparing(Category::getName))
                .map(child -> treeFrom(child, childrenByParentId))
                .toList();

        Category parent = category.getParent();
        return new CategoryResponse(
                category.getPublicId(),
                category.getName(),
                parent == null ? null : parent.getPublicId(),
                parent == null ? null : parent.getName(),
                childResponses);
    }
}
