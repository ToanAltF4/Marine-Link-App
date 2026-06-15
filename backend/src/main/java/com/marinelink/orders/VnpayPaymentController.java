package com.marinelink.orders;

import com.marinelink.common.api.ApiResponse;
import com.marinelink.common.exception.BusinessException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/payments/vnpay")
@RequiredArgsConstructor
public class VnpayPaymentController {

    private final VnpayPaymentService vnpayPaymentService;

    @PostMapping("/payment-url")
    public ApiResponse<VnpayPaymentUrlResponse> createPaymentUrl(
            Authentication authentication,
            @Valid @RequestBody VnpayPaymentUrlRequest request,
            HttpServletRequest servletRequest) {
        return ApiResponse.ok(vnpayPaymentService.createPaymentUrl(
                currentUserId(authentication),
                request.orderId(),
                request.bankCode(),
                clientIp(servletRequest)));
    }

    @PostMapping("/cancel")
    public ApiResponse<VnpayPaymentResultResponse> cancelPayment(
            Authentication authentication,
            @Valid @RequestBody VnpayPaymentCancelRequest request) {
        return ApiResponse.ok(
                vnpayPaymentService.cancelPendingPayment(
                        currentUserId(authentication),
                        request.orderId()),
                "VNPAY payment cancelled");
    }

    @GetMapping("/return")
    public ApiResponse<VnpayPaymentResultResponse> handleReturn(@RequestParam Map<String, String> params) {
        return ApiResponse.ok(vnpayPaymentService.handleReturn(params));
    }

    @GetMapping("/ipn")
    public VnpayIpnResponse handleIpn(@RequestParam Map<String, String> params) {
        return vnpayPaymentService.handleIpn(params);
    }

    private UUID currentUserId(Authentication authentication) {
        if (authentication == null || authentication.getName() == null) {
            throw new BusinessException("Authentication required", HttpStatus.UNAUTHORIZED);
        }
        try {
            return UUID.fromString(authentication.getName());
        } catch (IllegalArgumentException ex) {
            throw new BusinessException("Invalid authentication subject", HttpStatus.UNAUTHORIZED);
        }
    }

    private String clientIp(HttpServletRequest request) {
        String forwardedFor = request.getHeader("X-Forwarded-For");
        if (forwardedFor != null && !forwardedFor.isBlank()) {
            return forwardedFor.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}
