package com.marinelink.admin;

import com.marinelink.common.exception.GlobalExceptionHandler;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.math.BigDecimal;
import java.util.List;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class AdminDashboardControllerTest {

    private final AdminDashboardService service = mock(AdminDashboardService.class);

    private final MockMvc mockMvc = MockMvcBuilders
            .standaloneSetup(new AdminDashboardController(service))
            .setControllerAdvice(new GlobalExceptionHandler())
            .build();

    @Test
    void getDashboard_ShouldReturnOverview() throws Exception {
        when(service.getOverview()).thenReturn(new AdminDashboardResponse(
                5,
                new BigDecimal("125000000"),
                0,
                18,
                3,
                List.of(new AdminRecentOrderResponse(
                        "550e8400-e29b-41d4-a716-446655440009",
                        "ML-20260528-0001",
                        "PENDING",
                        new BigDecimal("4200000")))));

        mockMvc.perform(get("/api/admin/dashboard"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.pendingOrders").value(5))
                .andExpect(jsonPath("$.data.monthlyRevenue").value(125000000))
                .andExpect(jsonPath("$.data.activeUsers").value(18))
                .andExpect(jsonPath("$.data.lowStockProducts").value(3))
                .andExpect(jsonPath("$.data.newComplaints").value(0))
                .andExpect(jsonPath("$.data.recentOrders[0].orderCode").value("ML-20260528-0001"))
                .andExpect(jsonPath("$.data.recentOrders[0].status").value("PENDING"));
    }
}
