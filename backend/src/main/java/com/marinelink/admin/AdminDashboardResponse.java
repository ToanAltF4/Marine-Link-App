package com.marinelink.admin;

import java.math.BigDecimal;
import java.util.List;

/**
 * Admin dashboard overview aggregate.
 * Contract: GET /api/admin/dashboard (see docs/MarineLink_API_Documentation.md).
 */
public record AdminDashboardResponse(
        long pendingOrders,
        BigDecimal monthlyRevenue,
        long newComplaints,
        long activeUsers,
        long lowStockProducts,
        List<AdminRecentOrderResponse> recentOrders) {
}
