package com.marinelink.users;

import com.fasterxml.jackson.annotation.JsonProperty;

import java.time.Instant;
import java.util.UUID;

public record ShippingAddressResponse(
        UUID id,
        String label,
        String receiverName,
        String receiverPhone,
        String addressLine,
        @JsonProperty("default")
        boolean isDefault,
        Instant createdAt,
        Instant updatedAt) {

    public static ShippingAddressResponse from(ShippingAddress address) {
        return new ShippingAddressResponse(
                address.getPublicId(),
                address.getLabel(),
                address.getReceiverName(),
                address.getReceiverPhone(),
                address.getAddressLine(),
                address.isDefaultAddress(),
                address.getCreatedAt(),
                address.getUpdatedAt());
    }
}
