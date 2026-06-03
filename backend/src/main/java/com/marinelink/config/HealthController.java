package com.marinelink.config;

import com.marinelink.common.api.ApiResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.Map;

/**
 * Simple health check endpoint — publicly accessible.
 * GET /actuator/health alias at /api/health for Flutter app to ping.
 */
@RestController
@RequestMapping("/api/health")
public class HealthController {

    @GetMapping
    public ApiResponse<Map<String, Object>> health() {
        return ApiResponse.ok(Map.of(
            "status", "UP",
            "service", "marinelink-backend",
            "timestamp", Instant.now().toString()
        ));
    }
}
