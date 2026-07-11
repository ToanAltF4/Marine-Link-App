package com.marinelink.admin;

import com.marinelink.orders.CompletedOrderRevenueRow;
import com.marinelink.orders.OrderItemRepository;
import com.marinelink.orders.OrderRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Builds the ADMIN revenue report over a date range.
 * Revenue = sum of {@code totalAmount} of COMPLETED orders, bucketed by the day
 * boundaries of Vietnam local time (GMT+7).
 */
@Service
@RequiredArgsConstructor
public class AdminRevenueService {

    /** Days are grouped by Vietnam local time so the series matches the operator's calendar. */
    static final ZoneId VN_ZONE = ZoneId.of("Asia/Ho_Chi_Minh");

    /** Number of best-selling products returned. */
    private static final int TOP_PRODUCTS_LIMIT = 10;

    private final OrderRepository orderRepository;
    private final OrderItemRepository orderItemRepository;

    @Transactional(readOnly = true)
    public RevenueReportResponse getRevenue(LocalDate from, LocalDate to) {
        LocalDate resolvedFrom = from;
        LocalDate resolvedTo = to;

        // Default to the current VN month when either bound is missing.
        if (resolvedFrom == null || resolvedTo == null) {
            YearMonth month = YearMonth.now(VN_ZONE);
            resolvedFrom = month.atDay(1);
            resolvedTo = month.atEndOfMonth();
        }
        // Guard against an inverted range by swapping.
        if (resolvedFrom.isAfter(resolvedTo)) {
            LocalDate tmp = resolvedFrom;
            resolvedFrom = resolvedTo;
            resolvedTo = tmp;
        }

        Instant fromInstant = resolvedFrom.atStartOfDay(VN_ZONE).toInstant();
        Instant toInstant = resolvedTo.atTime(LocalTime.MAX).atZone(VN_ZONE).toInstant();

        List<CompletedOrderRevenueRow> rows =
                orderRepository.findCompletedRevenueBetween(com.marinelink.orders.OrderStatus.COMPLETED, fromInstant, toInstant);

        // Seed every day in range with zero so the daily dashboard has no gaps.
        Map<LocalDate, BigDecimal> byDay = new LinkedHashMap<>();
        for (LocalDate d = resolvedFrom; !d.isAfter(resolvedTo); d = d.plusDays(1)) {
            byDay.put(d, BigDecimal.ZERO);
        }

        BigDecimal totalRevenue = BigDecimal.ZERO;
        for (CompletedOrderRevenueRow row : rows) {
            if (row.completedAt() == null || row.totalAmount() == null) {
                continue;
            }
            LocalDate day = row.completedAt().atZone(VN_ZONE).toLocalDate();
            byDay.merge(day, row.totalAmount(), BigDecimal::add);
            totalRevenue = totalRevenue.add(row.totalAmount());
        }

        List<RevenueReportResponse.DailyRevenuePoint> dailySeries = new ArrayList<>();
        for (Map.Entry<LocalDate, BigDecimal> entry : byDay.entrySet()) {
            dailySeries.add(new RevenueReportResponse.DailyRevenuePoint(
                    entry.getKey().toString(), entry.getValue()));
        }

        List<RevenueReportResponse.TopProduct> topProducts = orderItemRepository
                .findTopProductsBetween(com.marinelink.orders.OrderStatus.COMPLETED, fromInstant, toInstant, PageRequest.of(0, TOP_PRODUCTS_LIMIT))
                .stream()
                .map(this::toTopProduct)
                .toList();

        return new RevenueReportResponse(
                resolvedFrom, resolvedTo, totalRevenue, dailySeries, topProducts);
    }

    private RevenueReportResponse.TopProduct toTopProduct(Object[] row) {
        UUID publicId = (UUID) row[0];
        String productName = (String) row[1];
        long quantitySold = ((Number) row[2]).longValue();
        BigDecimal revenue = (BigDecimal) row[3];
        return new RevenueReportResponse.TopProduct(
                publicId != null ? publicId.toString() : null,
                productName,
                quantitySold,
                revenue != null ? revenue : BigDecimal.ZERO);
    }
}
