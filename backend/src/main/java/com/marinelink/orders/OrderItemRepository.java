package com.marinelink.orders;

import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;

public interface OrderItemRepository extends JpaRepository<OrderItem, Long> {

    /**
     * Best-selling products across COMPLETED orders whose completion instant falls
     * within [from, to]. Each row: [product publicId (UUID), productNameSnapshot,
     * sum(quantity) (Long), sum(lineTotal) (BigDecimal)] ordered by quantity desc.
     */
    @Query("select oi.product.publicId, oi.productNameSnapshot, "
            + "sum(oi.quantity), sum(oi.lineTotal) "
            + "from OrderItem oi "
            + "where oi.order.status = :status "
            + "and oi.order.completedAt between :from and :to "
            + "group by oi.product.publicId, oi.productNameSnapshot "
            + "order by sum(oi.quantity) desc")
    List<Object[]> findTopProductsBetween(
            @Param("status") OrderStatus status,
            @Param("from") Instant from,
            @Param("to") Instant to,
            Pageable pageable);
}
