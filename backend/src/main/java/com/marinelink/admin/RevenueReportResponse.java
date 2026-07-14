package com.marinelink.admin;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * Revenue analytics aggregate for a resolved date range.
 * Contract: GET /api/admin/revenue (see docs/MarineLink_API_Documentation.md).
 *
 * <p>Days are bucketed by Vietnam local time (GMT+7) so the series lines up with
 * the operator's calendar day.
 */
public record RevenueReportResponse(
        LocalDate from,
        LocalDate to,
        BigDecimal totalRevenue,
        List<DailyRevenuePoint> dailySeries,
        List<TopProduct> topProducts) {

    /** Revenue for a single VN calendar day. */
    public record DailyRevenuePoint(String date, BigDecimal revenue) {
    }

    /** One best-selling product within the range. */
    public record TopProduct(
            String productId,
            String productName,
            long quantitySold,
            BigDecimal revenue) {
    }
}
