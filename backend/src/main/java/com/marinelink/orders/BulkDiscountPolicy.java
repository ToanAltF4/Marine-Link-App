package com.marinelink.orders;

import java.math.BigDecimal;

final class BulkDiscountPolicy {

    private static final BigDecimal TWO_PERCENT = new BigDecimal("0.02");
    private static final BigDecimal FOUR_PERCENT = new BigDecimal("0.04");
    private static final BigDecimal SIX_PERCENT = new BigDecimal("0.06");
    private static final BigDecimal EIGHT_PERCENT = new BigDecimal("0.08");

    private BulkDiscountPolicy() {
    }

    static BigDecimal rateForQuantity(int totalQuantity) {
        if (totalQuantity >= 500) {
            return EIGHT_PERCENT;
        }
        if (totalQuantity >= 200) {
            return SIX_PERCENT;
        }
        if (totalQuantity >= 100) {
            return FOUR_PERCENT;
        }
        if (totalQuantity >= 50) {
            return TWO_PERCENT;
        }
        return BigDecimal.ZERO;
    }
}
