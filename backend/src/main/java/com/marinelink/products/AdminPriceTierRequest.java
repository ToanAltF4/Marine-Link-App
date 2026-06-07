package com.marinelink.products;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;

public record AdminPriceTierRequest(
        @Min(value = 1, message = "Số lượng tối thiểu phải lớn hơn 0")
        int minQuantity,
        @Min(value = 1, message = "Số lượng tối đa phải lớn hơn 0")
        Integer maxQuantity,
        @NotNull(message = "Đơn giá không được để trống")
        @DecimalMin(value = "0", inclusive = false, message = "Đơn giá phải lớn hơn 0")
        BigDecimal unitPrice
) {
}
