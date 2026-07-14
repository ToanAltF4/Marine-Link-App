package com.marinelink.cart;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

public record CartResponse(
        UUID cartId,
        boolean isEmpty,
        List<CartItemResponse> items,
        int totalItemCount,
        int totalSelectedItemCount,
        BigDecimal subtotalAmount) {
}
