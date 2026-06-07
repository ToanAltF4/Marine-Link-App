package com.marinelink.admin;

import com.marinelink.orders.Order;
import com.marinelink.orders.OrderRepository;
import com.marinelink.orders.OrderStatus;
import com.marinelink.products.ProductRepository;
import com.marinelink.users.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.YearMonth;
import java.time.ZoneOffset;
import java.util.List;

/**
 * Aggregates the admin dashboard overview from orders, users and products.
 */
@Service
@RequiredArgsConstructor
public class AdminDashboardService {

    /** Products at or below this stock level are flagged as low stock. */
    private static final int LOW_STOCK_THRESHOLD = 10;

    private final OrderRepository orderRepository;
    private final ProductRepository productRepository;
    private final UserRepository userRepository;

    @Transactional(readOnly = true)
    public AdminDashboardResponse getOverview() {
        Instant startOfMonth = YearMonth.now(ZoneOffset.UTC)
                .atDay(1)
                .atStartOfDay(ZoneOffset.UTC)
                .toInstant();

        long pendingOrders = orderRepository.countByStatus(OrderStatus.PENDING);
        BigDecimal monthlyRevenue = orderRepository
                .sumTotalAmountByStatusCompletedAfter(OrderStatus.COMPLETED, startOfMonth);
        long activeUsers = userRepository.countActiveDealers();
        long lowStockProducts = productRepository.countLowStock(LOW_STOCK_THRESHOLD);
        // Complaints domain chưa tồn tại trong BE → trả 0 (placeholder tới khi có feature complaints).
        long newComplaints = 0;

        List<AdminRecentOrderResponse> recentOrders = orderRepository
                .findTop5ByOrderByCreatedAtDesc()
                .stream()
                .map(this::toRecentOrder)
                .toList();

        return new AdminDashboardResponse(
                pendingOrders,
                monthlyRevenue,
                newComplaints,
                activeUsers,
                lowStockProducts,
                recentOrders);
    }

    private AdminRecentOrderResponse toRecentOrder(Order order) {
        return new AdminRecentOrderResponse(
                order.getPublicId().toString(),
                order.getOrderCode(),
                order.getStatus().name(),
                order.getTotalAmount());
    }
}
