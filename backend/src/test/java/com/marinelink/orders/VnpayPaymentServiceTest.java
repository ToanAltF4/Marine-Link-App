package com.marinelink.orders;

import com.marinelink.cart.CartItemRepository;
import com.marinelink.cart.CartRepository;
import com.marinelink.common.exception.BusinessException;
import com.marinelink.users.User;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

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
    void createPaymentUrlEmbedsSignedWebClientReturnUrl() {
        UUID userId = UUID.randomUUID();
        UUID orderId = UUID.randomUUID();
        User user = User.builder().publicId(userId).build();
        PaymentMethod method = paymentMethod(PaymentMethodCode.VNPAY);
        Order order = Order.builder()
                .publicId(orderId)
                .orderCode("ML-20260616-0001")
                .user(user)
                .paymentMethod(method)
                .paymentStatus(PaymentStatus.PENDING)
                .totalAmount(new BigDecimal("850000"))
                .build();
        Payment payment = Payment.builder()
                .order(order)
                .paymentMethod(method)
                .amount(new BigDecimal("850000"))
                .status(PaymentStatus.PENDING)
                .txnRef("txn-001")
                .build();

        ReflectionTestUtils.setField(service, "tmnCode", "TESTTMN");
        ReflectionTestUtils.setField(service, "hashSecret", "0123456789abcdef");
        ReflectionTestUtils.setField(service, "paymentUrl", "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html");
        ReflectionTestUtils.setField(service, "returnUrl", "http://localhost:8080/api/payments/vnpay/return");
        when(orderRepository.findDetailByPublicId(orderId)).thenReturn(Optional.of(order));
        when(paymentRepository.findTopByOrderPublicIdOrderByCreatedAtDesc(orderId))
                .thenReturn(Optional.of(payment));

        VnpayPaymentUrlResponse response = service.createPaymentUrl(
                userId,
                orderId,
                null,
                "127.0.0.1",
                "http://localhost:3000/payments/vnpay/result");

        assertEquals("txn-001", response.txnRef());
        org.junit.jupiter.api.Assertions.assertTrue(response.paymentUrl().contains("clientReturnUrl"));
        org.junit.jupiter.api.Assertions.assertTrue(response.paymentUrl().contains("clientReturnSig"));
        verify(paymentRepository).save(payment);
    }

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
