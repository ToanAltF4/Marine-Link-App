package com.marinelink.orders;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.marinelink.common.exception.GlobalExceptionHandler;
import org.junit.jupiter.api.Test;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class OrderControllerTest {

    private final OrderService orderService = mock(OrderService.class);
    private final MockMvc mockMvc = MockMvcBuilders
            .standaloneSetup(new OrderController(orderService))
            .setControllerAdvice(new GlobalExceptionHandler())
            .build();
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Test
    void createOrderUsesCurrentUserAndReturnsCreatedEnvelope() throws Exception {
        UUID userId = UUID.fromString("550e8400-e29b-41d4-a716-446655440003");
        UUID orderId = UUID.fromString("550e8400-e29b-41d4-a716-446655440101");
        OrderCreateRequest request = new OrderCreateRequest(
                "Nguyen Van A",
                "0912345678",
                "Can Tho",
                PaymentMethod.COD,
                "Giao buoi sang",
                null);
        OrderSummaryResponse response = new OrderSummaryResponse(
                orderId,
                "ML-20260604-0001",
                OrderStatus.PENDING,
                PaymentMethod.COD,
                PaymentStatus.UNPAID,
                new BigDecimal("4200000"),
                BigDecimal.ZERO,
                BigDecimal.ZERO,
                new BigDecimal("4200000"),
                Instant.parse("2026-06-04T01:00:00Z"));

        when(orderService.createFromActiveCart(eq(userId), any(OrderCreateRequest.class)))
                .thenReturn(response);

        mockMvc.perform(post("/api/orders")
                        .principal(new TestingAuthenticationToken(userId.toString(), null))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("Order created"))
                .andExpect(jsonPath("$.data.id").value(orderId.toString()))
                .andExpect(jsonPath("$.data.orderCode").value("ML-20260604-0001"))
                .andExpect(jsonPath("$.data.status").value("PENDING"));
    }

    @Test
    void listOrdersReturnsPaginatedEnvelopeScopedByCurrentUser() throws Exception {
        UUID userId = UUID.fromString("550e8400-e29b-41d4-a716-446655440003");
        UUID orderId = UUID.fromString("550e8400-e29b-41d4-a716-446655440102");
        OrderListItemResponse order = new OrderListItemResponse(
                orderId,
                "ML-20260604-0002",
                OrderStatus.SHIPPING,
                new BigDecimal("1250000"),
                Instant.parse("2026-06-04T02:00:00Z"));

        when(orderService.listOrders(eq(userId), eq(false), eq(0), eq(20),
                eq(OrderStatus.SHIPPING), eq(null), eq(null)))
                .thenReturn(new PageImpl<>(List.of(order), PageRequest.of(0, 20), 1));

        mockMvc.perform(get("/api/orders")
                        .principal(new TestingAuthenticationToken(userId.toString(), null))
                        .queryParam("status", "SHIPPING"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].id").value(orderId.toString()))
                .andExpect(jsonPath("$.data[0].status").value("SHIPPING"))
                .andExpect(jsonPath("$.pagination.totalElements").value(1));
    }

    @Test
    void getOrderDetailReturnsItemsAndStatusTimeline() throws Exception {
        UUID userId = UUID.fromString("550e8400-e29b-41d4-a716-446655440003");
        UUID orderId = UUID.fromString("550e8400-e29b-41d4-a716-446655440103");
        UUID productId = UUID.fromString("550e8400-e29b-41d4-a716-446655440203");
        OrderDetailResponse detail = new OrderDetailResponse(
                orderId,
                "ML-20260604-0003",
                OrderStatus.PENDING,
                PaymentMethod.BANK_TRANSFER,
                PaymentStatus.UNPAID,
                "Nguyen Van A",
                "0912345678",
                "Can Tho",
                new BigDecimal("850000"),
                BigDecimal.ZERO,
                BigDecimal.ZERO,
                new BigDecimal("850000"),
                "Giao buoi sang",
                Instant.parse("2026-06-04T03:00:00Z"),
                List.of(new OrderItemResponse(
                        productId,
                        "Muc kho loai 1",
                        "kg",
                        new BigDecimal("425000"),
                        2,
                        new BigDecimal("850000"))),
                List.of(new OrderStatusHistoryResponse(
                        null,
                        OrderStatus.PENDING,
                        "Order created",
                        Instant.parse("2026-06-04T03:00:00Z"))));

        when(orderService.getOrderDetail(userId, false, orderId)).thenReturn(detail);

        mockMvc.perform(get("/api/orders/{id}", orderId)
                        .principal(new TestingAuthenticationToken(userId.toString(), null)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.items[0].productId").value(productId.toString()))
                .andExpect(jsonPath("$.data.items[0].lineTotal").value(850000))
                .andExpect(jsonPath("$.data.statusHistory[0].toStatus").value("PENDING"));
    }
}
