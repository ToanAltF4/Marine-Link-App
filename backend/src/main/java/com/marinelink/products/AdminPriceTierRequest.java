package com.marinelink.products;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Một mức giá sỉ trong payload tạo/cập nhật sản phẩm.
 *
 * <p>{@code id} là public id của mức giá đã tồn tại: client gửi lại để backend
 * cập nhật đúng dòng đó thay vì xoá rồi tạo mới (tránh vi phạm khoá ngoại từ
 * {@code cart_items.price_tier_id}). Mức giá mới gửi {@code id} null.
 */
public record AdminPriceTierRequest(
        UUID id,
        @Min(value = 1, message = "Số lượng tối thiểu phải lớn hơn 0")
        int minQuantity,
        @Min(value = 1, message = "Số lượng tối đa phải lớn hơn 0")
        Integer maxQuantity,
        @NotNull(message = "Đơn giá không được để trống")
        @DecimalMin(value = "0", inclusive = false, message = "Đơn giá phải lớn hơn 0")
        BigDecimal unitPrice
) {
}
