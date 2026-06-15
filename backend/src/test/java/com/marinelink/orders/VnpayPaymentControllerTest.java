package com.marinelink.orders;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.marinelink.common.exception.GlobalExceptionHandler;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.UUID;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class VnpayPaymentControllerTest {

    private final VnpayPaymentService vnpayPaymentService = mock(VnpayPaymentService.class);
    private final MockMvc mockMvc = MockMvcBuilders
            .standaloneSetup(new VnpayPaymentController(vnpayPaymentService))
            .setControllerAdvice(new GlobalExceptionHandler())
            .build();
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Test
    void ownerCanCancelPendingVnpayPayment() throws Exception {
        UUID userId = UUID.fromString("550e8400-e29b-41d4-a716-446655440003");
        UUID orderId = UUID.fromString("550e8400-e29b-41d4-a716-446655440105");
        VnpayPaymentCancelRequest request = new VnpayPaymentCancelRequest(orderId);
        VnpayPaymentResultResponse response = new VnpayPaymentResultResponse(
                "txn-001",
                "ML-20260615-0001",
                PaymentStatus.FAILED,
                "USER_CANCELLED",
                null,
                "Payment cancelled");

        when(vnpayPaymentService.cancelPendingPayment(eq(userId), eq(orderId)))
                .thenReturn(response);

        mockMvc.perform(post("/api/payments/vnpay/cancel")
                        .principal(new TestingAuthenticationToken(userId.toString(), null))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("VNPAY payment cancelled"))
                .andExpect(jsonPath("$.data.paymentStatus").value("FAILED"))
                .andExpect(jsonPath("$.data.responseCode").value("USER_CANCELLED"));
    }
}
