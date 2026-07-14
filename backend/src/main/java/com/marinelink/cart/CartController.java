package com.marinelink.cart;

import com.marinelink.common.api.ApiResponse;
import com.marinelink.common.exception.BusinessException;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/cart")
@RequiredArgsConstructor
public class CartController {

    private final CartService cartService;

    @GetMapping
    public ApiResponse<CartResponse> getActiveCart(Authentication authentication) {
        return ApiResponse.ok(
                cartService.getActiveCart(currentUserId(authentication)),
                "Cart loaded");
    }

    @PostMapping("/sync")
    public ApiResponse<CartResponse> sync(
            Authentication authentication,
            @Valid @RequestBody CartSyncRequest request) {
        return ApiResponse.ok(
                cartService.syncCart(currentUserId(authentication), request),
                "Cart synced");
    }

    @PostMapping("/items")
    public ApiResponse<CartResponse> addItem(
            Authentication authentication,
            @Valid @RequestBody CartItemCreateRequest request) {
        return ApiResponse.ok(
                cartService.addItem(currentUserId(authentication), request),
                "Cart item added");
    }

    @PatchMapping("/items/{productId}")
    public ApiResponse<CartResponse> updateItem(
            Authentication authentication,
            @PathVariable UUID productId,
            @Valid @RequestBody CartItemUpdateRequest request) {
        return ApiResponse.ok(
                cartService.updateItem(currentUserId(authentication), productId, request),
                "Cart item updated");
    }

    @DeleteMapping("/items/{productId}")
    public ApiResponse<CartResponse> removeItem(
            Authentication authentication,
            @PathVariable UUID productId) {
        return ApiResponse.ok(
                cartService.removeItem(currentUserId(authentication), productId),
                "Cart item removed");
    }

    @DeleteMapping("/items")
    public ApiResponse<CartResponse> clearItems(Authentication authentication) {
        return ApiResponse.ok(
                cartService.clearItems(currentUserId(authentication)),
                "Cart cleared");
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
}
