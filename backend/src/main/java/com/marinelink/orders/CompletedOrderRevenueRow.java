package com.marinelink.orders;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Lightweight projection of a COMPLETED order used for revenue reporting.
 * Only carries the completion timestamp and the order total.
 */
public record CompletedOrderRevenueRow(Instant completedAt, BigDecimal totalAmount) {
}
