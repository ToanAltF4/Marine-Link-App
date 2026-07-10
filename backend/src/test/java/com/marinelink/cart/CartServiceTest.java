package com.marinelink.cart;

import com.marinelink.products.Category;
import com.marinelink.products.PriceTier;
import com.marinelink.products.Product;
import com.marinelink.products.ProductRepository;
import com.marinelink.products.ProductStatus;
import com.marinelink.common.exception.BusinessException;
import com.marinelink.common.exception.ResourceNotFoundException;
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
import static org.junit.jupiter.api.Assertions.assertThrows;
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
    void getActiveCartHandlesDuplicateProductRowsWithoutSumming() {
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
        assertEquals(3, response.items().getFirst().quantity());
        assertEquals(3, response.totalSelectedItemCount());
        assertEquals(new BigDecimal("1350000"), response.subtotalAmount());
    }

    @Test
    void addItemSetsAbsoluteQuantityAndRecomputesTier() {
        UUID userPublicId = UUID.fromString("550e8400-e29b-41d4-a716-446655440003");
        UUID productPublicId = UUID.fromString("550e8400-e29b-41d4-a716-446655440012");
        User user = user(userPublicId);
        Product product = product(productPublicId);
        PriceTier tier = PriceTier.builder()
                .id(51L)
                .publicId(UUID.fromString("550e8400-e29b-41d4-a716-446655440051"))
                .product(product)
                .minQuantity(3)
                .unitPrice(new BigDecimal("400000"))
                .build();
        product.setPriceTiers(Set.of(tier));
        Cart cart = cart(user, product, 2);

        when(userRepository.findActiveByPublicId(userPublicId)).thenReturn(Optional.of(user));
        when(cartRepository.findActiveByUserPublicId(userPublicId)).thenReturn(Optional.of(cart));
        when(productRepository.findDetailByPublicId(productPublicId)).thenReturn(Optional.of(product));
        when(cartRepository.save(any(Cart.class))).thenAnswer(invocation -> invocation.getArgument(0));

        CartResponse response = cartService.addItem(
                userPublicId,
                new CartItemCreateRequest(productPublicId, 3, true));

        assertEquals(1, response.items().size());
        assertEquals(3, response.items().getFirst().quantity());
        assertEquals(new BigDecimal("1200000"), response.subtotalAmount());
        assertEquals(tier.getPublicId(), response.items().getFirst().selectedPriceTierId());
    }

    @Test
    void updateItemRejectsQuantityBelowMinimum() {
        UUID userPublicId = UUID.fromString("550e8400-e29b-41d4-a716-446655440003");
        UUID productPublicId = UUID.fromString("550e8400-e29b-41d4-a716-446655440012");
        User user = user(userPublicId);
        Product product = product(productPublicId);
        Cart cart = cart(user, product, 2);

        when(cartRepository.findActiveByUserPublicId(userPublicId)).thenReturn(Optional.of(cart));

        assertThrows(
                BusinessException.class,
                () -> cartService.updateItem(
                        userPublicId,
                        productPublicId,
                        new CartItemUpdateRequest(1, null)));
    }

    @Test
    void removeItemReturnsNotFoundWhenItemMissing() {
        UUID userPublicId = UUID.fromString("550e8400-e29b-41d4-a716-446655440003");
        UUID productPublicId = UUID.fromString("550e8400-e29b-41d4-a716-446655440012");
        Cart cart = Cart.builder()
                .id(31L)
                .publicId(UUID.fromString("550e8400-e29b-41d4-a716-446655440031"))
                .user(user(userPublicId))
                .build();

        when(cartRepository.findActiveByUserPublicId(userPublicId)).thenReturn(Optional.of(cart));

        assertThrows(
                ResourceNotFoundException.class,
                () -> cartService.removeItem(userPublicId, productPublicId));
    }

    @Test
    void clearItemsRemovesAllRowsAndReturnsEmptyCart() {
        UUID userPublicId = UUID.fromString("550e8400-e29b-41d4-a716-446655440003");
        UUID productPublicId = UUID.fromString("550e8400-e29b-41d4-a716-446655440012");
        User user = user(userPublicId);
        Product product = product(productPublicId);
        Cart cart = cart(user, product, 2);

        when(cartRepository.findActiveByUserPublicId(userPublicId)).thenReturn(Optional.of(cart));
        when(cartRepository.save(any(Cart.class))).thenAnswer(invocation -> invocation.getArgument(0));

        CartResponse response = cartService.clearItems(userPublicId);

        assertEquals(true, response.isEmpty());
        assertEquals(0, response.items().size());
        assertEquals(0, response.totalItemCount());
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

    private Cart cart(User user, Product product, int quantity) {
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
                .quantity(quantity)
                .selected(true)
                .build());
        return cart;
    }
}
