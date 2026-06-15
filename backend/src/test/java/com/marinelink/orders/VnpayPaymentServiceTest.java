package com.marinelink.orders;

import com.marinelink.cart.CartItemRepository;
import com.marinelink.cart.CartRepository;
import com.marinelink.common.exception.BusinessException;
import com.marinelink.users.User;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class VnpayPaymentServiceTest {

    private final OrderRepository orderRepository = mock(OrderRepository.class);
    private final PaymentRepository paymentRepository = mock(PaymentRepository.class);
    private final PaymentMethodRepository paymentMethodRepository = mock(PaymentMethodRepository.class);
    private final OrderPaymentNotificationService orderPaymentNotificationService =
            mock(OrderPaymentNotificationService.class);
    private final CartRepository cartRepository = mock(CartRepository.class);
    private final CartItemRepository cartItemRepository = mock(CartItemRepository.class);
    private final VnpayPaymentService service = new VnpayPaymentService(
            orderRepository,
            paymentRepository,
            paymentMethodRepository,
            orderPaymentNotificationService,
            cartRepository,
            cartItemRepository);

    @Test
    void cancelPendingPaymentMarksOrderCancelledAndPaymentFailed() {
        UUID userId = UUID.randomUUID();
        UUID orderId = UUID.randomUUID();
        User user = User.builder().publicId(userId).build();
        PaymentMethod method = paymentMethod(PaymentMethodCode.VNPAY);
        Order order = Order.builder()
                .publicId(orderId)
                .orderCode("ML-20260615-0001")
                .user(user)
                .status(OrderStatus.PENDING)
                .paymentMethod(method)
                .paymentStatus(PaymentStatus.PENDING)
                .build();
        Payment payment = Payment.builder()
                .order(order)
                .paymentMethod(method)
                .amount(new BigDecimal("850000"))
                .status(PaymentStatus.PENDING)
                .txnRef("txn-001")
                .build();

        when(orderRepository.findDetailByPublicId(orderId)).thenReturn(Optional.of(order));
        when(paymentRepository.findTopByOrderPublicIdOrderByCreatedAtDesc(orderId))
                .thenReturn(Optional.of(payment));

        VnpayPaymentResultResponse response = service.cancelPendingPayment(userId, orderId);

        assertEquals(PaymentStatus.FAILED, response.paymentStatus());
        assertEquals(OrderStatus.CANCELLED, order.getStatus());
        assertEquals(PaymentStatus.FAILED, order.getPaymentStatus());
        assertEquals("USER_CANCELLED", payment.getResponseCode());
        verify(paymentRepository).save(payment);
        verify(orderRepository).save(order);
    }

    @Test
    void cancelPendingPaymentRejectsPaidPayment() {
        UUID userId = UUID.randomUUID();
        UUID orderId = UUID.randomUUID();
        User user = User.builder().publicId(userId).build();
        PaymentMethod method = paymentMethod(PaymentMethodCode.VNPAY);
        Order order = Order.builder()
                .publicId(orderId)
                .user(user)
                .status(OrderStatus.PENDING)
                .paymentMethod(method)
                .paymentStatus(PaymentStatus.PAID)
                .build();

        when(orderRepository.findDetailByPublicId(orderId)).thenReturn(Optional.of(order));

        assertThrows(BusinessException.class, () -> service.cancelPendingPayment(userId, orderId));
    }

    private PaymentMethod paymentMethod(PaymentMethodCode code) {
        PaymentMethod paymentMethod = new PaymentMethod();
        paymentMethod.setPublicId(UUID.randomUUID());
        paymentMethod.setCode(code);
        paymentMethod.setName(code.name());
        paymentMethod.setActive(true);
        return paymentMethod;
    }
}
