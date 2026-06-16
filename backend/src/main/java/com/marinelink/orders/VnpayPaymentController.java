package com.marinelink.orders;

import com.marinelink.common.api.ApiResponse;
import com.marinelink.common.exception.BusinessException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.util.UriComponentsBuilder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.net.URI;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/payments/vnpay")
@RequiredArgsConstructor
public class VnpayPaymentController {

    private final VnpayPaymentService vnpayPaymentService;

    @Value("${app.vnpay.frontend-return-url:marinelink:///payments/vnpay/result}")
    private String frontendReturnUrl = "marinelink:///payments/vnpay/result";

    @PostMapping("/payment-url")
    public ApiResponse<VnpayPaymentUrlResponse> createPaymentUrl(
            Authentication authentication,
            @Valid @RequestBody VnpayPaymentUrlRequest request,
            HttpServletRequest servletRequest) {
        return ApiResponse.ok(vnpayPaymentService.createPaymentUrl(
                currentUserId(authentication),
                request.orderId(),
                request.bankCode(),
                clientIp(servletRequest),
                clientReturnUrl(servletRequest)));
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
    public ResponseEntity<Void> handleReturn(@RequestParam Map<String, String> params) {
        VnpayPaymentResultResponse result = vnpayPaymentService.handleReturn(params);
        return ResponseEntity.status(HttpStatus.FOUND)
                .location(frontendReturnUri(result, params))
                .build();
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

    private URI frontendReturnUri(VnpayPaymentResultResponse result) {
        return frontendReturnUri(result, Map.of());
    }

    private URI frontendReturnUri(
            VnpayPaymentResultResponse result,
            Map<String, String> params) {
        String targetReturnUrl = trustedClientReturnUrl(params);
        UriComponentsBuilder builder = UriComponentsBuilder
                .fromUriString(targetReturnUrl == null ? frontendReturnUrl.trim() : targetReturnUrl)
                .queryParam("success", result.paymentStatus() == PaymentStatus.PAID)
                .queryParam("txnRef", result.txnRef())
                .queryParam("orderCode", result.orderCode())
                .queryParam("paymentStatus", result.paymentStatus() == null ? null : result.paymentStatus().name())
                .queryParam("responseCode", result.responseCode())
                .queryParam("transactionStatus", result.transactionStatus())
                .queryParam("message", result.message());
        return builder.build().encode().toUri();
    }

    private String trustedClientReturnUrl(Map<String, String> params) {
        String clientReturnUrl = trimToNull(params.get("clientReturnUrl"));
        if (clientReturnUrl == null || !isAllowedFrontendReturnUrl(clientReturnUrl)) {
            return null;
        }
        if (!vnpayPaymentService.hasValidClientReturnUrlSignature(params)) {
            return null;
        }
        return clientReturnUrl;
    }

    private String clientReturnUrl(HttpServletRequest request) {
        String origin = trimToNull(request.getHeader("Origin"));
        if (origin == null) {
            origin = originFromReferer(request.getHeader("Referer"));
        }
        if (origin == null) {
            return null;
        }
        try {
            URI uri = URI.create(origin);
            if (!isHttpScheme(uri)) {
                return null;
            }
            return UriComponentsBuilder.fromUri(uri)
                    .replacePath("/payments/vnpay/result")
                    .replaceQuery(null)
                    .fragment(null)
                    .build()
                    .toUriString();
        } catch (IllegalArgumentException ex) {
            return null;
        }
    }

    private String originFromReferer(String referer) {
        String value = trimToNull(referer);
        if (value == null) {
            return null;
        }
        try {
            URI uri = URI.create(value);
            if (!isHttpScheme(uri) || uri.getHost() == null) {
                return null;
            }
            return UriComponentsBuilder.newInstance()
                    .scheme(uri.getScheme())
                    .host(uri.getHost())
                    .port(uri.getPort())
                    .build()
                    .toUriString();
        } catch (IllegalArgumentException ex) {
            return null;
        }
    }

    private boolean isAllowedFrontendReturnUrl(String value) {
        try {
            URI uri = URI.create(value);
            if (!isHttpScheme(uri) || uri.getHost() == null) {
                return false;
            }
            if (!"/payments/vnpay/result".equals(uri.getPath())) {
                return false;
            }
            if (isLocalHost(uri.getHost())) {
                return true;
            }
            URI configured = URI.create(frontendReturnUrl.trim());
            return isHttpScheme(configured)
                    && uri.getScheme().equalsIgnoreCase(configured.getScheme())
                    && uri.getHost().equalsIgnoreCase(configured.getHost())
                    && uri.getPort() == configured.getPort();
        } catch (IllegalArgumentException ex) {
            return false;
        }
    }

    private boolean isHttpScheme(URI uri) {
        return "http".equalsIgnoreCase(uri.getScheme())
                || "https".equalsIgnoreCase(uri.getScheme());
    }

    private boolean isLocalHost(String host) {
        return "localhost".equalsIgnoreCase(host)
                || "127.0.0.1".equals(host)
                || "::1".equals(host)
                || "[::1]".equals(host);
    }

    private String trimToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
