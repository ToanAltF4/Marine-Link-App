package com.marinelink.admin;

import com.marinelink.orders.CompletedOrderRevenueRow;
import com.marinelink.orders.OrderItemRepository;
import com.marinelink.orders.OrderRepository;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.time.YearMonth;
import java.time.ZoneId;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class AdminRevenueServiceTest {

    private static final ZoneId VN = ZoneId.of("Asia/Ho_Chi_Minh");

    private final OrderRepository orderRepository = mock(OrderRepository.class);
    private final OrderItemRepository orderItemRepository = mock(OrderItemRepository.class);

    private final AdminRevenueService service =
            new AdminRevenueService(orderRepository, orderItemRepository);

    @Test
    void getRevenue_DefaultsToCurrentMonth_WhenRangeMissing() {
        when(orderRepository.findCompletedRevenueBetween(any(), any(), any())).thenReturn(List.of());
        when(orderItemRepository.findTopProductsBetween(any(), any(), any(), any())).thenReturn(List.of());

        RevenueReportResponse result = service.getRevenue(null, null);

        YearMonth month = YearMonth.now(VN);
        assertThat(result.from()).isEqualTo(month.atDay(1));
        assertThat(result.to()).isEqualTo(month.atEndOfMonth());
        // Daily series covers every day of the month, seeded with zeros.
        assertThat(result.dailySeries()).hasSize(month.lengthOfMonth());
        assertThat(result.totalRevenue()).isEqualByComparingTo("0");
        assertThat(result.topProducts()).isEmpty();
    }

    @Test
    void getRevenue_BucketsByVietnamDay_AndSumsTotal() {
        LocalDate from = LocalDate.of(2026, 6, 1);
        LocalDate to = LocalDate.of(2026, 6, 3);

        // 2026-06-01T18:00Z == 2026-06-02T01:00 VN → bucketed into June 2.
        CompletedOrderRevenueRow lateNightUtc = new CompletedOrderRevenueRow(
                Instant.parse("2026-06-01T18:00:00Z"), new BigDecimal("1000000"));
        // 2026-06-02T02:00Z == 2026-06-02T09:00 VN → also June 2.
        CompletedOrderRevenueRow sameVnDay = new CompletedOrderRevenueRow(
                Instant.parse("2026-06-02T02:00:00Z"), new BigDecimal("500000"));
        // 2026-06-02T20:00Z == 2026-06-03T03:00 VN → June 3.
        CompletedOrderRevenueRow nextVnDay = new CompletedOrderRevenueRow(
                Instant.parse("2026-06-02T20:00:00Z"), new BigDecimal("250000"));

        when(orderRepository.findCompletedRevenueBetween(any(), any(), any()))
                .thenReturn(List.of(lateNightUtc, sameVnDay, nextVnDay));
        when(orderItemRepository.findTopProductsBetween(any(), any(), any(), any())).thenReturn(List.of());

        RevenueReportResponse result = service.getRevenue(from, to);

        assertThat(result.from()).isEqualTo(from);
        assertThat(result.to()).isEqualTo(to);
        assertThat(result.totalRevenue()).isEqualByComparingTo("1750000");
        assertThat(result.dailySeries()).hasSize(3);
        assertThat(result.dailySeries().get(0).date()).isEqualTo("2026-06-01");
        assertThat(result.dailySeries().get(0).revenue()).isEqualByComparingTo("0");
        assertThat(result.dailySeries().get(1).date()).isEqualTo("2026-06-02");
        assertThat(result.dailySeries().get(1).revenue()).isEqualByComparingTo("1500000");
        assertThat(result.dailySeries().get(2).date()).isEqualTo("2026-06-03");
        assertThat(result.dailySeries().get(2).revenue()).isEqualByComparingTo("250000");
    }

    @Test
    void getRevenue_MapsTopProducts() {
        UUID productId = UUID.fromString("550e8400-e29b-41d4-a716-446655440777");
        Object[] row = new Object[] {productId, "Mực khô loại 1", 42L, new BigDecimal("8400000")};

        when(orderRepository.findCompletedRevenueBetween(any(), any(), any())).thenReturn(List.of());
        when(orderItemRepository.findTopProductsBetween(any(), any(), any(), any()))
                .thenReturn(List.<Object[]>of(row));

        RevenueReportResponse result = service.getRevenue(
                LocalDate.of(2026, 6, 1), LocalDate.of(2026, 6, 30));

        assertThat(result.topProducts()).hasSize(1);
        RevenueReportResponse.TopProduct top = result.topProducts().get(0);
        assertThat(top.productId()).isEqualTo(productId.toString());
        assertThat(top.productName()).isEqualTo("Mực khô loại 1");
        assertThat(top.quantitySold()).isEqualTo(42L);
        assertThat(top.revenue()).isEqualByComparingTo("8400000");
    }
}
