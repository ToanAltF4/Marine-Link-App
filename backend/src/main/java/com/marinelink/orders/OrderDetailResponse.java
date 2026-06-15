package com.marinelink.orders;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;

public record OrderDetailResponse(
        UUID id,
        String orderCode,
        OrderStatus status,
        PaymentMethodCode paymentMethod,
        PaymentStatus paymentStatus,
        String receiverName,
        String receiverPhone,
        String shippingAddress,
        BigDecimal subtotalAmount,
        BigDecimal shippingFee,
        BigDecimal discountAmount,
        BigDecimal totalAmount,
        String note,
        Instant createdAt,
        List<OrderItemResponse> items,
        List<OrderStatusHistoryResponse> statusHistory) {

    public static OrderDetailResponse from(Order order) {
        List<OrderItemResponse> items = order.getItems()
                .stream()
                .map(OrderItemResponse::from)
                .toList();
        List<OrderStatusHistoryResponse> history = order.getStatusHistory()
                .stream()
                .sorted(Comparator.comparing(OrderStatusHistory::getCreatedAt))
                .map(OrderStatusHistoryResponse::from)
                .toList();
        return new OrderDetailResponse(
                order.getPublicId(),
                order.getOrderCode(),
                order.getStatus(),
                order.getPaymentMethod().getCode(),
                order.getPaymentStatus(),
                order.getReceiverName(),
                order.getReceiverPhone(),
                order.getShippingAddress(),
                order.getSubtotalAmount(),
                order.getShippingFee(),
                order.getDiscountAmount(),
                order.getTotalAmount(),
                order.getNote(),
                order.getCreatedAt(),
                items,
                history);
    }
}
