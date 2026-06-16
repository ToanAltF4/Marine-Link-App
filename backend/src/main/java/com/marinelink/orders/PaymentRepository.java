package com.marinelink.orders;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface PaymentRepository extends JpaRepository<Payment, Long> {

    @EntityGraph(attributePaths = {"order", "order.user", "paymentMethod"})
    Optional<Payment> findByTxnRef(String txnRef);

    @EntityGraph(attributePaths = {"order", "order.user", "paymentMethod"})
    Optional<Payment> findTopByOrderPublicIdOrderByCreatedAtDesc(UUID orderPublicId);

    @EntityGraph(attributePaths = {"order", "order.user", "paymentMethod"})
    Optional<Payment> findTopByOrderOrderByCreatedAtDesc(Order order);
}
