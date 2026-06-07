package com.marinelink.warehouses;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class WarehouseService {

    private final WarehouseRepository warehouseRepository;

    @Transactional(readOnly = true)
    public List<WarehouseResponse> listActiveWarehouses() {
        return warehouseRepository.findByActiveTrueOrderByNameAsc()
                .stream()
                .map(WarehouseResponse::from)
                .toList();
    }
}
