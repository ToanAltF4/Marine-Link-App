package com.marinelink.warehouses;

import com.fasterxml.jackson.annotation.JsonProperty;

import java.math.BigDecimal;
import java.util.UUID;

public record WarehouseResponse(
        UUID id,
        String name,
        String address,
        String phone,
        String openingHours,
        BigDecimal latitude,
        BigDecimal longitude,
        @JsonProperty("isActive") boolean active) {

    public static WarehouseResponse from(Warehouse warehouse) {
        return new WarehouseResponse(
                warehouse.getPublicId(),
                warehouse.getName(),
                warehouse.getAddress(),
                warehouse.getPhone(),
                warehouse.getOpeningHours(),
                warehouse.getLatitude(),
                warehouse.getLongitude(),
                warehouse.isActive());
    }
}
