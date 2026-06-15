package com.marinelink.cart;

import com.marinelink.products.Category;
import com.marinelink.products.PriceTier;
import com.marinelink.products.Product;
import com.marinelink.products.ProductRepository;
import com.marinelink.products.ProductStatus;
import com.marinelink.users.Role;
import com.marinelink.users.User;
import com.marinelink.users.UserRepository;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class CartServiceTest {

    private final CartRepository cartRepository = mock(CartRepository.class);
    private final ProductRepository productRepository = mock(ProductRepository.class);
    private final UserRepository userRepository = mock(UserRepository.class);
    private final CartService cartService = new CartService(
            cartRepository,
            productRepository,
            userRepository);

    @Test
    void syncCartCreatesServerCartAndRecomputesTierTotals() {
        UUID userPublicId = UUID.fromString("550e8400-e29b-41d4-a716-446655440003");
        UUID productPublicId = UUID.fromString("550e8400-e29b-41d4-a716-446655440012");
        User user = user(userPublicId);
        Product product = product(productPublicId);
        PriceTier tier = PriceTier.builder()
                .id(51L)
                .publicId(UUID.fromString("550e8400-e29b-41d4-a716-446655440051"))
                .product(product)
                .minQuantity(2)
                .maxQuantity(9)
                .unitPrice(new BigDecimal("425000"))
                .build();
        product.setPriceTiers(Set.of(tier));

        when(userRepository.findActiveByPublicId(userPublicId)).thenReturn(Optional.of(user));
        when(cartRepository.findActiveByUserPublicId(userPublicId)).thenReturn(Optional.empty());
        when(productRepository.findDetailByPublicId(productPublicId)).thenReturn(Optional.of(product));
        when(cartRepository.save(any(Cart.class))).thenAnswer(invocation -> {
            Cart cart = invocation.getArgument(0);
            cart.setId(31L);
            cart.setPublicId(UUID.fromString("550e8400-e29b-41d4-a716-446655440031"));
            return cart;
        });

        CartResponse response = cartService.syncCart(
                userPublicId,
                new CartSyncRequest(List.of(new CartSyncItemRequest(productPublicId, 2, true))));

        assertEquals(false, response.isEmpty());
        assertEquals(1, response.items().size());
        assertEquals(new BigDecimal("850000"), response.subtotalAmount());
        assertEquals(tier.getPublicId(), response.items().getFirst().selectedPriceTierId());
    }

    @Test
    void getActiveCartMergesDuplicateProductRowsForDisplay() {
        UUID userPublicId = UUID.fromString("550e8400-e29b-41d4-a716-446655440003");
        UUID productPublicId = UUID.fromString("550e8400-e29b-41d4-a716-446655440012");
        User user = user(userPublicId);
        Product product = product(productPublicId);
        Cart cart = Cart.builder()
                .id(31L)
                .publicId(UUID.fromString("550e8400-e29b-41d4-a716-446655440031"))
                .user(user)
                .build();
        cart.getItems().add(CartItem.builder()
                .id(41L)
                .publicId(UUID.fromString("550e8400-e29b-41d4-a716-446655440041"))
                .cart(cart)
                .product(product)
                .quantity(2)
                .selected(true)
                .build());
        cart.getItems().add(CartItem.builder()
                .id(42L)
                .publicId(UUID.fromString("550e8400-e29b-41d4-a716-446655440042"))
                .cart(cart)
                .product(product)
                .quantity(3)
                .selected(true)
                .build());

        when(cartRepository.findActiveByUserPublicId(userPublicId)).thenReturn(Optional.of(cart));

        CartResponse response = cartService.getActiveCart(userPublicId);

        assertEquals(1, response.items().size());
        assertEquals(5, response.items().getFirst().quantity());
        assertEquals(5, response.totalSelectedItemCount());
        assertEquals(new BigDecimal("2250000"), response.subtotalAmount());
    }

    private User user(UUID publicId) {
        return User.builder()
                .id(21L)
                .publicId(publicId)
                .role(Role.builder().code("USER").build())
                .fullName("Nguyen Van A")
                .email(publicId + "@example.com")
                .phone("0912345678")
                .passwordHash("hash")
                .build();
    }

    private Product product(UUID publicId) {
        Category category = Category.builder()
                .id(11L)
                .publicId(UUID.fromString("550e8400-e29b-41d4-a716-446655440011"))
                .name("Muc kho")
                .slug("muc-kho")
                .build();
        return Product.builder()
                .id(12L)
                .publicId(publicId)
                .category(category)
                .name("Muc kho loai 1")
                .slug("muc-kho-loai-1")
                .imageUrl("https://example.com/muc-kho.png")
                .basePrice(new BigDecimal("450000"))
                .unit("kg")
                .minOrderQuantity(2)
                .stockQuantity(20)
                .status(ProductStatus.ACTIVE)
                .build();
    }
}
