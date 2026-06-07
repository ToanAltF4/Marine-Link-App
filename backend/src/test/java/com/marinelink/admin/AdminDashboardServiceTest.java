package com.marinelink.admin;

import com.marinelink.orders.Order;
import com.marinelink.orders.OrderRepository;
import com.marinelink.orders.OrderStatus;
import com.marinelink.products.ProductRepository;
import com.marinelink.users.UserRepository;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class AdminDashboardServiceTest {

    private final OrderRepository orderRepository = mock(OrderRepository.class);
    private final ProductRepository productRepository = mock(ProductRepository.class);
    private final UserRepository userRepository = mock(UserRepository.class);

    private final AdminDashboardService service = new AdminDashboardService(
            orderRepository, productRepository, userRepository);

    @Test
    void getOverview_AggregatesFromRepositories() {
        Order recent = Order.builder()
                .id(1L)
                .publicId(UUID.randomUUID())
                .orderCode("ML-20260528-0001")
                .status(OrderStatus.PENDING)
                .totalAmount(new BigDecimal("4200000"))
                .createdAt(Instant.now())
                .build();

        when(orderRepository.countByStatus(OrderStatus.PENDING)).thenReturn(7L);
        when(orderRepository.sumTotalAmountByStatusCompletedAfter(eq(OrderStatus.COMPLETED), any()))
                .thenReturn(new BigDecimal("125000000"));
        when(userRepository.countActiveDealers()).thenReturn(18L);
        when(productRepository.countLowStock(anyInt())).thenReturn(3L);
        when(orderRepository.findTop5ByOrderByCreatedAtDesc()).thenReturn(List.of(recent));

        AdminDashboardResponse result = service.getOverview();

        assertThat(result.pendingOrders()).isEqualTo(7);
        assertThat(result.monthlyRevenue()).isEqualByComparingTo("125000000");
        assertThat(result.activeUsers()).isEqualTo(18);
        assertThat(result.lowStockProducts()).isEqualTo(3);
        assertThat(result.newComplaints()).isZero();
        assertThat(result.recentOrders()).hasSize(1);
        assertThat(result.recentOrders().get(0).orderCode()).isEqualTo("ML-20260528-0001");
        assertThat(result.recentOrders().get(0).status()).isEqualTo("PENDING");
    }
}
