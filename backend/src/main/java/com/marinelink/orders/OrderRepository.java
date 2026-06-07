package com.marinelink.orders;

import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface OrderRepository extends JpaRepository<Order, Long>, JpaSpecificationExecutor<Order> {

    @Override
    @EntityGraph(attributePaths = {"user"})
    org.springframework.data.domain.Page<Order> findAll(
            Specification<Order> spec,
            org.springframework.data.domain.Pageable pageable);

    @EntityGraph(attributePaths = {"user", "items", "items.product", "statusHistory", "statusHistory.changedBy"})
    @Query("select o from Order o where o.publicId = :publicId")
    Optional<Order> findDetailByPublicId(@Param("publicId") UUID publicId);

    long countByCreatedAtBetween(Instant from, Instant to);

    long countByStatus(OrderStatus status);

    @Query("select coalesce(sum(o.totalAmount), 0) from Order o "
            + "where o.status = :status and o.completedAt >= :from")
    BigDecimal sumTotalAmountByStatusCompletedAfter(
            @Param("status") OrderStatus status,
            @Param("from") Instant from);

    @EntityGraph(attributePaths = {"user"})
    List<Order> findTop5ByOrderByCreatedAtDesc();
}
