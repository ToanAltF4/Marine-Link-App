package com.marinelink.cart;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface CartItemRepository extends JpaRepository<CartItem, Long> {

    @Modifying
    @Query("delete from CartItem item where item.cart.id = :cartId and item.selected = true")
    void deleteSelectedByCartId(@Param("cartId") Long cartId);
}
