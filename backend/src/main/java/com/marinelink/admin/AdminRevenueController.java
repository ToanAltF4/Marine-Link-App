package com.marinelink.admin;

import com.marinelink.common.api.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;

/**
 * Admin revenue analytics endpoint.
 * Access is restricted to ADMIN at the URL level (SecurityConfig: /api/admin/**).
 */
@RestController
@RequestMapping("/api/admin/revenue")
@RequiredArgsConstructor
public class AdminRevenueController {

    private final AdminRevenueService adminRevenueService;

    /**
     * Revenue report over [from, to] (both inclusive, VN local dates).
     * When either bound is omitted the current month is used.
     */
    @GetMapping
    public ApiResponse<RevenueReportResponse> getRevenue(
            @RequestParam(value = "from", required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(value = "to", required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return ApiResponse.ok(adminRevenueService.getRevenue(from, to));
    }
}
