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
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.when;

class OrderServiceTest {

    private final OrderRepository orderRepository = mock(OrderRepository.class);
    private final CartRepository cartRepository = mock(CartRepository.class);
    private final CartItemRepository cartItemRepository = mock(CartItemRepository.class);
    private final ProductRepository productRepository = mock(ProductRepository.class);
    private final UserRepository userRepository = mock(UserRepository.class);
    private final PaymentMethodRepository paymentMethodRepository = mock(PaymentMethodRepository.class);
    private final PaymentRepository paymentRepository = mock(PaymentRepository.class);
    private final NotificationService notificationService = mock(NotificationService.class);
    private final OrderPaymentNotificationService orderPaymentNotificationService =
            mock(OrderPaymentNotificationService.class);
    private final OrderService orderService = new OrderService(
            orderRepository,
            cartRepository,
            cartItemRepository,
            productRepository,
            userRepository,
            paymentMethodRepository,
            paymentRepository,
            notificationService,
            orderPaymentNotificationService);

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
        when(paymentMethodRepository.findByCodeAndActiveTrue(PaymentMethodCode.COD))
                .thenReturn(Optional.of(paymentMethod(PaymentMethodCode.COD)));
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
                        PaymentMethodCode.COD,
                        "Giao buoi sang",
                        null));

        assertEquals(OrderStatus.PENDING, response.status());
        assertEquals(new BigDecimal("850000"), response.totalAmount());
        verify(cartItemRepository).deleteSelectedByCartId(31L);
        verify(orderPaymentNotificationService).notifyOrderWaitingForApproval(any(Order.class));
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
        when(paymentMethodRepository.findByCodeAndActiveTrue(PaymentMethodCode.COD))
                .thenReturn(Optional.of(paymentMethod(PaymentMethodCode.COD)));
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
                        PaymentMethodCode.COD,
                        "Giao buoi sang",
                        List.of(new OrderCreateItemRequest(product.getPublicId(), 2))));

        assertEquals(OrderStatus.PENDING, response.status());
        assertEquals(new BigDecimal("850000"), response.totalAmount());
    }

    @Test
    void createOrderAppliesBulkDiscountForRequestItems() {
        UUID userPublicId = UUID.fromString("550e8400-e29b-41d4-a716-446655440003");
        User user = user(userPublicId);
        Product product = product();

        when(userRepository.findActiveByPublicId(userPublicId)).thenReturn(Optional.of(user));
        when(paymentMethodRepository.findByCodeAndActiveTrue(PaymentMethodCode.COD))
                .thenReturn(Optional.of(paymentMethod(PaymentMethodCode.COD)));
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
                        PaymentMethodCode.COD,
                        null,
                        List.of(new OrderCreateItemRequest(product.getPublicId(), 50))));

        assertEquals(new BigDecimal("22500000"), response.subtotalAmount());
        assertEquals(new BigDecimal("450000.00"), response.discountAmount());
        assertEquals(new BigDecimal("22050000.00"), response.totalAmount());
    }

    @Test
    void createBankTransferOrderWaitsForPaymentBeforeNotification() {
        UUID userPublicId = UUID.fromString("550e8400-e29b-41d4-a716-446655440003");
        User user = user(userPublicId);
        Product product = product();

        when(userRepository.findActiveByPublicId(userPublicId)).thenReturn(Optional.of(user));
        when(paymentMethodRepository.findByCodeAndActiveTrue(PaymentMethodCode.BANK_TRANSFER))
                .thenReturn(Optional.of(paymentMethod(PaymentMethodCode.BANK_TRANSFER)));
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
                        PaymentMethodCode.BANK_TRANSFER,
                        null,
                        List.of(new OrderCreateItemRequest(product.getPublicId(), 2))));

        assertEquals(PaymentStatus.PENDING, response.paymentStatus());
        verify(orderPaymentNotificationService, never()).notifyPaidOrderWaitingForApproval(any(Order.class));
    }

    @Test
    void createBankTransferOrderFromServerCartDoesNotClearCartBeforePayment() {
        UUID userPublicId = UUID.fromString("550e8400-e29b-41d4-a716-446655440003");
        User user = user(userPublicId);
        Product product = product();
        Cart cart = Cart.builder()
                .id(31L)
                .publicId(UUID.fromString("550e8400-e29b-41d4-a716-446655440031"))
                .user(user)
                .build();
        cart.getItems().add(CartItem.builder()
                .id(41L)
                .cart(cart)
                .product(product)
                .quantity(2)
                .selected(true)
                .build());

        when(userRepository.findActiveByPublicId(userPublicId)).thenReturn(Optional.of(user));
        when(paymentMethodRepository.findByCodeAndActiveTrue(PaymentMethodCode.BANK_TRANSFER))
                .thenReturn(Optional.of(paymentMethod(PaymentMethodCode.BANK_TRANSFER)));
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
                        PaymentMethodCode.BANK_TRANSFER,
                        null,
                        null));

        assertEquals(PaymentStatus.PENDING, response.paymentStatus());
        verify(cartItemRepository, never()).deleteSelectedByCartId(31L);
        verify(orderPaymentNotificationService, never()).notifyOrderWaitingForApproval(any(Order.class));
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
                .paymentMethod(paymentMethod(PaymentMethodCode.COD))
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

    @Test
    void updateStatusRejectsBankTransferApprovalBeforePayment() {
        UUID staffPublicId = UUID.randomUUID();
        UUID orderPublicId = UUID.randomUUID();
        User staff = user(staffPublicId);
        Order order = Order.builder()
                .publicId(orderPublicId)
                .orderCode("ML-20260615-0002")
                .user(user(UUID.randomUUID()))
                .status(OrderStatus.PENDING)
                .paymentMethod(paymentMethod(PaymentMethodCode.BANK_TRANSFER))
                .paymentStatus(PaymentStatus.PENDING)
                .build();

        when(userRepository.findActiveByPublicId(staffPublicId)).thenReturn(Optional.of(staff));
        when(orderRepository.findDetailByPublicId(orderPublicId)).thenReturn(Optional.of(order));

        assertThrows(
                com.marinelink.common.exception.BusinessException.class,
                () -> orderService.updateStatus(staffPublicId, orderPublicId, OrderStatus.CONFIRMED, null));
        verify(orderRepository, never()).save(any(Order.class));
    }

    @Test
    void updatePaymentStatusNotifiesOnlyWhenPaymentBecomesPaid() {
        UUID staffPublicId = UUID.randomUUID();
        UUID orderPublicId = UUID.randomUUID();
        User staff = user(staffPublicId);
        User customer = user(UUID.randomUUID());
        Order order = Order.builder()
                .publicId(orderPublicId)
                .orderCode("ML-20260615-0001")
                .user(customer)
                .paymentMethod(paymentMethod(PaymentMethodCode.BANK_TRANSFER))
                .paymentStatus(PaymentStatus.PENDING)
                .build();
        Payment payment = Payment.builder()
                .order(order)
                .paymentMethod(paymentMethod(PaymentMethodCode.BANK_TRANSFER))
                .status(PaymentStatus.PENDING)
                .amount(new BigDecimal("850000"))
                .txnRef("manual-001")
                .build();
        Cart cart = Cart.builder()
                .id(31L)
                .publicId(UUID.randomUUID())
                .user(customer)
                .build();

        when(userRepository.findActiveByPublicId(staffPublicId)).thenReturn(Optional.of(staff));
        when(orderRepository.findDetailByPublicId(orderPublicId)).thenReturn(Optional.of(order));
        when(paymentRepository.findTopByOrderOrderByCreatedAtDesc(order)).thenReturn(Optional.of(payment));
        when(orderRepository.save(order)).thenReturn(order);
        when(cartRepository.findActiveByUserPublicId(customer.getPublicId())).thenReturn(Optional.of(cart));

        OrderPaymentStatusUpdateResponse response = orderService.updatePaymentStatus(
                staffPublicId,
                orderPublicId,
                PaymentStatus.PAID,
                "Da nhan chuyen khoan");

        assertEquals(PaymentStatus.PAID, response.paymentStatus());
        verify(paymentRepository).save(payment);
        verify(cartItemRepository).deleteSelectedByCartId(31L);
        verify(orderPaymentNotificationService).notifyPaidOrderWaitingForApproval(order);
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
                .stockQuantity(600)
                .status(ProductStatus.ACTIVE)
                .build();
    }

    private PaymentMethod paymentMethod(PaymentMethodCode code) {
        PaymentMethod paymentMethod = new PaymentMethod();
        paymentMethod.setId(91L);
        paymentMethod.setPublicId(UUID.randomUUID());
        paymentMethod.setCode(code);
        paymentMethod.setName(code.name());
        paymentMethod.setActive(true);
        return paymentMethod;
    }
}
