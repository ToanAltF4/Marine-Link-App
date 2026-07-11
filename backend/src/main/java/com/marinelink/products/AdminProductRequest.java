package com.marinelink.products;

import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

public record AdminProductRequest(
        UUID categoryId,
        @NotBlank(message = "Tên sản phẩm không được để trống")
        @Size(max = 180, message = "Tên sản phẩm tối đa 180 ký tự")
        String name,
        @NotBlank(message = "Slug không được để trống")
        @Size(max = 180, message = "Slug tối đa 180 ký tự")
        String slug,
        @Size(max = 240, message = "Mô tả tóm tắt tối đa 240 ký tự")
        String shortDescription,
        @Size(max = 2000, message = "Mô tả tối đa 2000 ký tự")
        String description,
        @Size(max = 120, message = "Xuất xứ tối đa 120 ký tự")
        String origin,
        @Size(max = 500, message = "URL ảnh tối đa 500 ký tự")
        String imageUrl,
        @NotNull(message = "Giá gốc không được để trống")
        @DecimalMin(value = "0", inclusive = false, message = "Giá gốc phải lớn hơn 0")
        BigDecimal basePrice,
        @NotBlank(message = "Đơn vị không được để trống")
        @Size(max = 20, message = "Đơn vị tối đa 20 ký tự")
        String unit,
        @Min(value = 1, message = "Số lượng tối thiểu phải lớn hơn 0")
        int minOrderQuantity,
        @Min(value = 0, message = "Tồn kho không được âm")
        int stockQuantity,
        @NotNull(message = "Trạng thái không được để trống")
        ProductStatus status,
        boolean isFeatured,
        List<@Valid AdminPriceTierRequest> priceTiers
) {
}
