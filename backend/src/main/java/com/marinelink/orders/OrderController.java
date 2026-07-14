package com.marinelink.orders;

import com.marinelink.common.api.ApiResponse;
import com.marinelink.common.exception.BusinessException;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/orders")
@RequiredArgsConstructor
public class OrderController {

    private final OrderService orderService;

    @PostMapping
    public ResponseEntity<ApiResponse<OrderSummaryResponse>> create(
            Authentication authentication,
            @Valid @RequestBody OrderCreateRequest request) {
        OrderSummaryResponse response = orderService.createFromActiveCart(
                currentUserId(authentication),
                request);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.created(response, "Order created"));
    }

    @GetMapping
    public ApiResponse<List<OrderListItemResponse>> list(
            Authentication authentication,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) OrderStatus status,
            @RequestParam(required = false) String fromDate,
            @RequestParam(required = false) String toDate) {
        Page<OrderListItemResponse> orders = orderService.listOrders(
                currentUserId(authentication),
                canViewAllOrders(authentication),
                page,
                size,
                status,
                fromDate,
                toDate);
        return ApiResponse.ok(orders.getContent(), ApiResponse.PaginationMeta.of(orders));
    }

    @GetMapping("/{id}")
    public ApiResponse<OrderDetailResponse> detail(
            Authentication authentication,
            @PathVariable UUID id) {
        return ApiResponse.ok(orderService.getOrderDetail(
                currentUserId(authentication),
                canViewAllOrders(authentication),
                id));
    }

    @PutMapping("/{id}/status")
    public ApiResponse<OrderStatusUpdateResponse> updateStatus(
            Authentication authentication,
            @PathVariable UUID id,
            @Valid @RequestBody OrderStatusUpdateRequest request) {
        return ApiResponse.ok(
                orderService.updateStatus(
                        currentUserId(authentication),
                        id,
                        request.status(),
                        request.note()),
                "Order status updated");
    }

    @PutMapping("/{id}/payment-status")
    public ApiResponse<OrderPaymentStatusUpdateResponse> updatePaymentStatus(
            Authentication authentication,
            @PathVariable UUID id,
            @Valid @RequestBody OrderPaymentStatusUpdateRequest request) {
        return ApiResponse.ok(
                orderService.updatePaymentStatus(
                        currentUserId(authentication),
                        id,
                        request.status(),
                        request.note()),
                "Order payment status updated");
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

    private boolean canViewAllOrders(Authentication authentication) {
        if (authentication == null) {
            return false;
        }
        return authentication.getAuthorities()
                .stream()
                .anyMatch(authority ->
                        authority.getAuthority().equals("ROLE_STAFF")
                                || authority.getAuthority().equals("ROLE_ADMIN"));
    }
}
