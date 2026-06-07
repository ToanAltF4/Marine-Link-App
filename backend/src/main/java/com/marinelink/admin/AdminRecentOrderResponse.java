package com.marinelink.admin;

import java.math.BigDecimal;

/**
 * One row of the admin dashboard "recent orders" list.
 * Mirrors {@code recentOrders[]} in GET /api/admin/dashboard.
 */
public record AdminRecentOrderResponse(
        String id,
        String orderCode,
        String status,
        BigDecimal totalAmount) {
}
