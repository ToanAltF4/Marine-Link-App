package com.marinelink.users;

import com.marinelink.common.api.ApiResponse;
import com.marinelink.common.exception.BusinessException;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/users/me/shipping-addresses")
@RequiredArgsConstructor
public class ShippingAddressController {

    private final ShippingAddressService shippingAddressService;

    @GetMapping
    public ApiResponse<List<ShippingAddressResponse>> list(Authentication authentication) {
        return ApiResponse.ok(shippingAddressService.listForUser(currentUserId(authentication)));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<ShippingAddressResponse>> create(
            Authentication authentication,
            @Valid @RequestBody ShippingAddressRequest request) {
        ShippingAddressResponse response = shippingAddressService.createForUser(
                currentUserId(authentication),
                request);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.created(response, "Shipping address created"));
    }

    @PutMapping("/{id}")
    public ApiResponse<ShippingAddressResponse> update(
            Authentication authentication,
            @PathVariable UUID id,
            @Valid @RequestBody ShippingAddressRequest request) {
        return ApiResponse.ok(shippingAddressService.updateForUser(
                currentUserId(authentication),
                id,
                request));
    }

    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(Authentication authentication, @PathVariable UUID id) {
        shippingAddressService.deleteForUser(currentUserId(authentication), id);
        return ApiResponse.ok(null, "Shipping address deleted");
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
