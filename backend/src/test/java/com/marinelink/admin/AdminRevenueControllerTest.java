package com.marinelink.admin;

import com.marinelink.common.security.JwtTokenProvider;
import com.marinelink.config.SecurityConfig;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(AdminRevenueController.class)
@Import(SecurityConfig.class)
class AdminRevenueControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private AdminRevenueService adminRevenueService;

    @MockBean
    private JwtTokenProvider jwtTokenProvider;

    private RevenueReportResponse sampleReport() {
        return new RevenueReportResponse(
                LocalDate.of(2026, 6, 1),
                LocalDate.of(2026, 6, 3),
                new BigDecimal("1750000"),
                List.of(
                        new RevenueReportResponse.DailyRevenuePoint("2026-06-01", BigDecimal.ZERO),
                        new RevenueReportResponse.DailyRevenuePoint("2026-06-02", new BigDecimal("1500000")),
                        new RevenueReportResponse.DailyRevenuePoint("2026-06-03", new BigDecimal("250000"))),
                List.of(new RevenueReportResponse.TopProduct(
                        "550e8400-e29b-41d4-a716-446655440777",
                        "Mực khô loại 1",
                        42L,
                        new BigDecimal("8400000"))));
    }

    @Test
    void getRevenue_AsAdmin_ReturnsReportAndForwardsRange() throws Exception {
        when(adminRevenueService.getRevenue(
                eq(LocalDate.of(2026, 6, 1)), eq(LocalDate.of(2026, 6, 3))))
                .thenReturn(sampleReport());

        mockMvc.perform(get("/api/admin/revenue")
                        .queryParam("from", "2026-06-01")
                        .queryParam("to", "2026-06-03")
                        .with(user("admin").roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.from").value("2026-06-01"))
                .andExpect(jsonPath("$.data.to").value("2026-06-03"))
                .andExpect(jsonPath("$.data.totalRevenue").value(1750000))
                .andExpect(jsonPath("$.data.dailySeries[1].date").value("2026-06-02"))
                .andExpect(jsonPath("$.data.dailySeries[1].revenue").value(1500000))
                .andExpect(jsonPath("$.data.topProducts[0].productName").value("Mực khô loại 1"))
                .andExpect(jsonPath("$.data.topProducts[0].quantitySold").value(42));

        verify(adminRevenueService).getRevenue(
                LocalDate.of(2026, 6, 1), LocalDate.of(2026, 6, 3));
    }

    @Test
    void getRevenue_WithoutRange_DefaultsAndReturnsOk() throws Exception {
        when(adminRevenueService.getRevenue(null, null)).thenReturn(sampleReport());

        mockMvc.perform(get("/api/admin/revenue")
                        .with(user("admin").roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));

        verify(adminRevenueService).getRevenue(null, null);
    }

    @Test
    void getRevenue_AsNonAdmin_IsForbidden() throws Exception {
        mockMvc.perform(get("/api/admin/revenue")
                        .with(user("dealer").roles("USER")))
                .andExpect(status().isForbidden());
    }
}
