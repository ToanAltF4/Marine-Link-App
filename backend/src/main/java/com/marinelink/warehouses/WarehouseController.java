package com.marinelink.warehouses;

import com.marinelink.common.api.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/warehouses")
@RequiredArgsConstructor
public class WarehouseController {

    private final WarehouseService warehouseService;

    @GetMapping
    public ApiResponse<List<WarehouseResponse>> listWarehouses() {
        return ApiResponse.ok(warehouseService.listActiveWarehouses());
    }
}
