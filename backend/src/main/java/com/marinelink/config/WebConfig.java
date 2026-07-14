package com.marinelink.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * General Web MVC configuration.
 * CORS is handled in {@link SecurityConfig}; this class is kept for any
 * additional MVC customization (formatters, message converters, etc.).
 */
@Configuration
public class WebConfig implements WebMvcConfigurer {
    // Additional MVC configuration can be added here in future sprints.
}
