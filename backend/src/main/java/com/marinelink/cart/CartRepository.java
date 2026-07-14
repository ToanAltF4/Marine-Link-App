package com.marinelink.cart;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;
import java.util.UUID;

public interface CartRepository extends JpaRepository<Cart, Long> {

    @EntityGraph(attributePaths = {
            "items",
            "items.product",
            "items.product.priceTiers",
            "items.priceTier"
    })
    @Query("select c from Cart c where c.user.publicId = :userPublicId")
    Optional<Cart> findActiveByUserPublicId(@Param("userPublicId") UUID userPublicId);
}
