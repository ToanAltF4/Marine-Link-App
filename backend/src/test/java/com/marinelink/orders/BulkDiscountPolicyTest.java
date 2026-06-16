package com.marinelink.orders;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.assertEquals;

class BulkDiscountPolicyTest {

    @Test
    void rateForQuantityUsesWholesaleKilogramTiers() {
        assertEquals(BigDecimal.ZERO, BulkDiscountPolicy.rateForQuantity(49));
        assertEquals(new BigDecimal("0.02"), BulkDiscountPolicy.rateForQuantity(50));
        assertEquals(new BigDecimal("0.02"), BulkDiscountPolicy.rateForQuantity(99));
        assertEquals(new BigDecimal("0.04"), BulkDiscountPolicy.rateForQuantity(100));
        assertEquals(new BigDecimal("0.04"), BulkDiscountPolicy.rateForQuantity(199));
        assertEquals(new BigDecimal("0.06"), BulkDiscountPolicy.rateForQuantity(200));
        assertEquals(new BigDecimal("0.06"), BulkDiscountPolicy.rateForQuantity(499));
        assertEquals(new BigDecimal("0.08"), BulkDiscountPolicy.rateForQuantity(500));
    }
}
