package com.marinelink.warehouses;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class WarehouseServiceTest {

    private final WarehouseRepository warehouseRepository = mock(WarehouseRepository.class);
    private final WarehouseService service = new WarehouseService(warehouseRepository);

    @Test
    void listActiveWarehousesMapsPublicFieldsOnly() {
        Warehouse warehouse = Warehouse.builder()
                .id(99L)
                .publicId(UUID.fromString("550e8400-e29b-41d4-a716-446655460001"))
                .name("Kho Can Tho")
                .address("123 Tran Hung Dao, Can Tho")
                .phone("0292000000")
                .openingHours("08:00-17:00")
                .latitude(new BigDecimal("10.0452000"))
                .longitude(new BigDecimal("105.7469000"))
                .active(true)
                .build();

        when(warehouseRepository.findByActiveTrueOrderByNameAsc()).thenReturn(List.of(warehouse));

        List<WarehouseResponse> result = service.listActiveWarehouses();

        assertThat(result).hasSize(1);
        assertThat(result.get(0).id()).isEqualTo(warehouse.getPublicId());
        assertThat(result.get(0).name()).isEqualTo("Kho Can Tho");
        assertThat(result.get(0).active()).isTrue();
    }
}
