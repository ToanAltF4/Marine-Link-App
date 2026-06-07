package com.marinelink.orders;

import com.marinelink.cart.Cart;
import com.marinelink.cart.CartItem;
import com.marinelink.cart.CartItemRepository;
import com.marinelink.cart.CartRepository;
import com.marinelink.common.exception.ResourceNotFoundException;
import com.marinelink.notifications.NotificationService;
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
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class OrderServiceTest {

    private final OrderRepository orderRepository = mock(OrderRepository.class);
    private final CartRepository cartRepository = mock(CartRepository.class);
    private final CartItemRepository cartItemRepository = mock(CartItemRepository.class);
    private final ProductRepository productRepository = mock(ProductRepository.class);
    private final UserRepository userRepository = mock(UserRepository.class);
    private final NotificationService notificationService = mock(NotificationService.class);
    private final OrderService orderService = new OrderService(
            orderRepository,
            cartRepository,
            cartItemRepository,
            productRepository,
            userRepository,
            notificationService);

    @Test
    void createFromActiveCartSnapshotsSelectedItemsAndClearsCart() {
        UUID userPublicId = UUID.fromString("550e8400-e29b-41d4-a716-446655440003");
        User user = user(userPublicId);
        Product product = product();
        PriceTier tier = PriceTier.builder()
                .id(51L)
                .publicId(UUID.fromString("550e8400-e29b-41d4-a716-446655440051"))
                .product(product)
                .minQuantity(2)
                .maxQuantity(9)
                .unitPrice(new BigDecimal("425000"))
                .build();
        product.setPriceTiers(Set.of(tier));
        Cart cart = Cart.builder()
                .id(31L)
                .publicId(UUID.fromString("550e8400-e29b-41d4-a716-446655440031"))
                .user(user)
                .build();
        cart.getItems().add(CartItem.builder()
                .id(41L)
                .cart(cart)
                .product(product)
                .priceTier(tier)
                .quantity(2)
                .selected(true)
                .build());

        when(userRepository.findActiveByPublicId(userPublicId)).thenReturn(Optional.of(user));
        when(cartRepository.findActiveByUserPublicId(userPublicId)).thenReturn(Optional.of(cart));
        when(orderRepository.countByCreatedAtBetween(any(), any())).thenReturn(0L);
        when(orderRepository.save(any(Order.class))).thenAnswer(invocation -> {
            Order order = invocation.getArgument(0);
            order.setId(61L);
            order.setCreatedAt(Instant.parse("2026-06-04T01:00:00Z"));
            return order;
        });

        OrderSummaryResponse response = orderService.createFromActiveCart(
                userPublicId,
                new OrderCreateRequest(
                        "Nguyen Van A",
                        "0912345678",
                        "Can Tho",
                        PaymentMethod.COD,
                        "Giao buoi sang",
                        null));

        assertEquals(OrderStatus.PENDING, response.status());
        assertEquals(new BigDecimal("850000"), response.totalAmount());
        verify(cartItemRepository).deleteSelectedByCartId(31L);
    }

    @Test
    void createOrderCanUseRequestItemsWhenServerCartIsMissing() {
        UUID userPublicId = UUID.fromString("550e8400-e29b-41d4-a716-446655440003");
        User user = user(userPublicId);
        Product product = product();
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
        when(productRepository.findDetailByPublicId(product.getPublicId())).thenReturn(Optional.of(product));
        when(orderRepository.countByCreatedAtBetween(any(), any())).thenReturn(0L);
        when(orderRepository.save(any(Order.class))).thenAnswer(invocation -> {
            Order order = invocation.getArgument(0);
            order.setId(61L);
            order.setCreatedAt(Instant.parse("2026-06-04T01:00:00Z"));
            return order;
        });

        OrderSummaryResponse response = orderService.createFromActiveCart(
                userPublicId,
                new OrderCreateRequest(
                        "Nguyen Van A",
                        "0912345678",
                        "Can Tho",
                        PaymentMethod.COD,
                        "Giao buoi sang",
                        List.of(new OrderCreateItemRequest(product.getPublicId(), 2))));

        assertEquals(OrderStatus.PENDING, response.status());
        assertEquals(new BigDecimal("850000"), response.totalAmount());
    }

    @Test
    void getOrderDetailHidesOtherUsersOrders() {
        UUID currentUser = UUID.fromString("550e8400-e29b-41d4-a716-446655440003");
        UUID otherUser = UUID.fromString("550e8400-e29b-41d4-a716-446655440004");
        UUID orderId = UUID.fromString("550e8400-e29b-41d4-a716-446655440101");
        Order order = Order.builder()
                .publicId(orderId)
                .orderCode("ML-20260604-0001")
                .user(user(otherUser))
                .status(OrderStatus.PENDING)
                .paymentMethod(PaymentMethod.COD)
                .paymentStatus(PaymentStatus.UNPAID)
                .receiverName("Nguyen Van B")
                .receiverPhone("0987654321")
                .shippingAddress("Ca Mau")
                .subtotalAmount(BigDecimal.ZERO)
                .shippingFee(BigDecimal.ZERO)
                .discountAmount(BigDecimal.ZERO)
                .totalAmount(BigDecimal.ZERO)
                .createdAt(Instant.parse("2026-06-04T01:00:00Z"))
                .build();
        when(orderRepository.findDetailByPublicId(orderId)).thenReturn(Optional.of(order));

        assertThrows(
                ResourceNotFoundException.class,
                () -> orderService.getOrderDetail(currentUser, false, orderId));
    }

    @Test
    void updateStatus_ShouldSendNotification() {
        UUID adminPublicId = UUID.randomUUID();
        UUID orderPublicId = UUID.randomUUID();
        User admin = user(adminPublicId);
        User customer = user(UUID.randomUUID());
        Order order = Order.builder()
                .publicId(orderPublicId)
                .orderCode("ML-20260604-0001")
                .user(customer)
                .status(OrderStatus.PENDING)
                .build();

        when(userRepository.findActiveByPublicId(adminPublicId)).thenReturn(Optional.of(admin));
        when(orderRepository.findDetailByPublicId(orderPublicId)).thenReturn(Optional.of(order));
        when(orderRepository.save(any(Order.class))).thenReturn(order);

        orderService.updateStatus(adminPublicId, orderPublicId, OrderStatus.CONFIRMED, "Confirmed by admin");

        verify(notificationService).createNotification(
                eq(customer),
                any(),
                anyString(),
                anyString(),
                any()
        );
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

    private Product product() {
        Category category = Category.builder()
                .id(11L)
                .publicId(UUID.fromString("550e8400-e29b-41d4-a716-446655440011"))
                .name("Muc kho")
                .slug("muc-kho")
                .build();
        return Product.builder()
                .id(12L)
                .publicId(UUID.fromString("550e8400-e29b-41d4-a716-446655440012"))
                .category(category)
                .name("Muc kho loai 1")
                .slug("muc-kho-loai-1")
                .basePrice(new BigDecimal("450000"))
                .unit("kg")
                .minOrderQuantity(2)
                .stockQuantity(20)
                .status(ProductStatus.ACTIVE)
                .build();
    }
}
