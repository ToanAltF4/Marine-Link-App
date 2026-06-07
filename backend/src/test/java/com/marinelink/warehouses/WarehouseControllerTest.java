package com.marinelink.warehouses;

import com.marinelink.common.exception.GlobalExceptionHandler;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class WarehouseControllerTest {

    private final WarehouseService warehouseService = mock(WarehouseService.class);
    private final MockMvc mockMvc = MockMvcBuilders
            .standaloneSetup(new WarehouseController(warehouseService))
            .setControllerAdvice(new GlobalExceptionHandler())
            .build();

    @Test
    void listWarehousesReturnsEnvelope() throws Exception {
        WarehouseResponse warehouse = new WarehouseResponse(
                UUID.fromString("550e8400-e29b-41d4-a716-446655460001"),
                "Kho Can Tho",
                "123 Tran Hung Dao, Can Tho",
                "0292000000",
                "08:00-17:00",
                new BigDecimal("10.0452000"),
                new BigDecimal("105.7469000"),
                true);

        when(warehouseService.listActiveWarehouses()).thenReturn(List.of(warehouse));

        mockMvc.perform(get("/api/warehouses").contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].id").value("550e8400-e29b-41d4-a716-446655460001"))
                .andExpect(jsonPath("$.data[0].name").value("Kho Can Tho"))
                .andExpect(jsonPath("$.data[0].latitude").value(10.0452000))
                .andExpect(jsonPath("$.data[0].longitude").value(105.7469000))
                .andExpect(jsonPath("$.data[0].isActive").value(true));
    }
}
