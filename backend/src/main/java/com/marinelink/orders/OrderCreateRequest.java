package com.marinelink.orders;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.util.List;

public record OrderCreateRequest(
        @NotBlank @Size(max = 120) String receiverName,
        @NotBlank @Pattern(regexp = "^[0-9+\\-\\s]{8,20}$") String receiverPhone,
        @NotBlank @Size(max = 500) String shippingAddress,
        @NotNull PaymentMethod paymentMethod,
        @Size(max = 500) String note,
        @Size(max = 100) List<@Valid OrderCreateItemRequest> items) {
}
