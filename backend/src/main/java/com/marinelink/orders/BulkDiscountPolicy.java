package com.marinelink.orders;

import java.math.BigDecimal;

final class BulkDiscountPolicy {

    private static final BigDecimal FIVE_PERCENT = new BigDecimal("0.05");
    private static final BigDecimal TEN_PERCENT = new BigDecimal("0.10");

    private BulkDiscountPolicy() {
    }

    static BigDecimal rateForQuantity(int totalQuantity) {
        if (totalQuantity >= 10) {
            return TEN_PERCENT;
        }
        if (totalQuantity >= 5) {
            return FIVE_PERCENT;
        }
        return BigDecimal.ZERO;
    }
}
