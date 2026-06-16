package com.marinelink.orders;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.marinelink.common.exception.GlobalExceptionHandler;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.UUID;

import static org.hamcrest.Matchers.containsString;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
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
    void webPaymentUrlUsesBrowserOriginAsClientReturnUrl() throws Exception {
        UUID userId = UUID.fromString("550e8400-e29b-41d4-a716-446655440003");
        UUID orderId = UUID.fromString("550e8400-e29b-41d4-a716-446655440105");
        VnpayPaymentUrlRequest request = new VnpayPaymentUrlRequest(orderId, "NCB");
        VnpayPaymentUrlResponse response = new VnpayPaymentUrlResponse(
                orderId,
                "ML-20260615-0001",
                "txn-001",
                "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html");

        when(vnpayPaymentService.createPaymentUrl(
                eq(userId),
                eq(orderId),
                eq("NCB"),
                anyString(),
                eq("http://localhost:3000/payments/vnpay/result")))
                .thenReturn(response);

        mockMvc.perform(post("/api/payments/vnpay/payment-url")
                        .principal(new TestingAuthenticationToken(userId.toString(), null))
                        .header("Origin", "http://localhost:3000")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.txnRef").value("txn-001"));
    }

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

    @Test
    void returnRedirectsToFrontendResultPage() throws Exception {
        VnpayPaymentResultResponse response = new VnpayPaymentResultResponse(
                "txn-001",
                "ML-20260614-0027",
                PaymentStatus.PAID,
                "00",
                "00",
                "Confirm Success");

        when(vnpayPaymentService.handleReturn(org.mockito.ArgumentMatchers.anyMap()))
                .thenReturn(response);

        mockMvc.perform(get("/api/payments/vnpay/return")
                        .queryParam("vnp_TxnRef", "txn-001"))
                .andExpect(status().isFound())
                .andExpect(header().string("Location", containsString("marinelink:///payments/vnpay/result")))
                .andExpect(header().string("Location", containsString("/payments/vnpay/result")))
                .andExpect(header().string("Location", containsString("success=true")))
                .andExpect(header().string("Location", containsString("orderCode=ML-20260614-0027")))
                .andExpect(header().string("Location", containsString("paymentStatus=PAID")))
                .andExpect(header().string("Location", containsString("responseCode=00")));
    }

    @Test
    void returnRedirectsToTrustedWebClientResultPage() throws Exception {
        VnpayPaymentResultResponse response = new VnpayPaymentResultResponse(
                "txn-001",
                "ML-20260614-0027",
                PaymentStatus.PAID,
                "00",
                "00",
                "Confirm Success");

        when(vnpayPaymentService.handleReturn(org.mockito.ArgumentMatchers.anyMap()))
                .thenReturn(response);
        when(vnpayPaymentService.hasValidClientReturnUrlSignature(org.mockito.ArgumentMatchers.anyMap()))
                .thenReturn(true);

        mockMvc.perform(get("/api/payments/vnpay/return")
                        .queryParam("clientReturnUrl", "http://localhost:3000/payments/vnpay/result")
                        .queryParam("clientReturnSig", "signed")
                        .queryParam("vnp_TxnRef", "txn-001"))
                .andExpect(status().isFound())
                .andExpect(header().string(
                        "Location",
                        containsString("http://localhost:3000/payments/vnpay/result")))
                .andExpect(header().string("Location", containsString("success=true")))
                .andExpect(header().string("Location", containsString("paymentStatus=PAID")));
    }

    @Test
    void returnIgnoresUntrustedWebClientResultPage() throws Exception {
        VnpayPaymentResultResponse response = new VnpayPaymentResultResponse(
                "txn-001",
                "ML-20260614-0027",
                PaymentStatus.PAID,
                "00",
                "00",
                "Confirm Success");

        when(vnpayPaymentService.handleReturn(org.mockito.ArgumentMatchers.anyMap()))
                .thenReturn(response);
        when(vnpayPaymentService.hasValidClientReturnUrlSignature(org.mockito.ArgumentMatchers.anyMap()))
                .thenReturn(true);

        mockMvc.perform(get("/api/payments/vnpay/return")
                        .queryParam("clientReturnUrl", "https://evil.test/payments/vnpay/result")
                        .queryParam("clientReturnSig", "signed")
                        .queryParam("vnp_TxnRef", "txn-001"))
                .andExpect(status().isFound())
                .andExpect(header().string("Location", containsString("marinelink:///payments/vnpay/result")));
    }
}
