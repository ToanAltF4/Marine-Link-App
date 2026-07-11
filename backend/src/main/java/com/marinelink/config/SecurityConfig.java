package com.marinelink.config;

import com.marinelink.common.security.JwtAuthenticationFilter;
import com.marinelink.common.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.Arrays;
import java.util.List;

/**
 * Spring Security configuration.
 *
 * <ul>
 *   <li>Stateless JWT — no HttpSession created.</li>
 *   <li>Public: POST /api/auth/login, POST /api/auth/register, GET /api/products, GET /api/products/*, GET /api/warehouses</li>
 *   <li>Admin-only: /api/admin/**</li>
 *   <li>Authenticated: everything else.</li>
 * </ul>
 */
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtTokenProvider jwtTokenProvider;

    @Value("${app.cors.allowed-origins:http://localhost:3000}")
    private String allowedOrigins;

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public JwtAuthenticationFilter jwtAuthenticationFilter() {
        return new JwtAuthenticationFilter(jwtTokenProvider);
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(AbstractHttpConfigurer::disable)
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            .sessionManagement(session ->
                session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                // Public endpoints
                .requestMatchers(HttpMethod.POST,
                    "/api/auth/login",
                    "/api/auth/google",
                    "/api/auth/register",
                    "/api/auth/verify-email",
                    "/api/auth/resend-otp",
                    "/api/auth/forgot-password",
                    "/api/auth/reset-password").permitAll()
                // WebSocket handshake (STOMP auth happens on the CONNECT frame)
                .requestMatchers("/ws/**", "/ws").permitAll()
                .requestMatchers(HttpMethod.GET,
                    "/api/auth/email-availability",
                    "/api/auth/phone-availability",
                    "/api/products", "/api/products/**",
                    "/api/payments/vnpay/return",
                    "/api/payments/vnpay/ipn",
                    "/api/warehouses",
                    "/swagger-ui/**", "/swagger-ui.html",
                    "/api-docs/**", "/api-docs",
                    "/actuator/health").permitAll()
                // Product management: staff can also update stock / add products
                .requestMatchers("/api/admin/products", "/api/admin/products/**")
                    .hasAnyRole("STAFF", "ADMIN")
                // Admin-only
                .requestMatchers("/api/admin/**").hasRole("ADMIN")
                // Staff workspace
                .requestMatchers("/api/staff/**").hasAnyRole("STAFF", "ADMIN")
                // Staff + Admin for order status updates
                .requestMatchers(HttpMethod.PUT, "/api/orders/*/status")
                    .hasAnyRole("STAFF", "ADMIN")
                .requestMatchers(HttpMethod.PUT, "/api/orders/*/payment-status")
                    .hasAnyRole("STAFF", "ADMIN")
                // Everything else requires authentication
                .anyRequest().authenticated()
            )
            .addFilterBefore(jwtAuthenticationFilter(),
                UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();
        // Support all localhost ports for easy development
        config.setAllowedOriginPatterns(List.of(
            "http://localhost:[*]",
            "http://127.0.0.1:[*]",
            "https://localhost:[*]",
            "https://127.0.0.1:[*]"
        ));
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"));
        config.setAllowedHeaders(List.of("*"));
        config.setAllowCredentials(true);
        config.setMaxAge(3600L); // Cache preflight response for 1 hour

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config); // Apply to all paths including /ws
        return source;
    }
}
