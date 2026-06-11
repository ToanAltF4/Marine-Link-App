package com.marinelink.auth.google;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.marinelink.common.exception.BusinessException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Verifies Google ID tokens via Google's tokeninfo endpoint.
 *
 * <p>Google validates the signature/expiry server-side and returns the decoded
 * claims; we additionally enforce that the audience ({@code aud}) is one of our
 * configured OAuth client IDs ({@code app.google.client-ids}) and that the
 * email is verified.
 */
@Slf4j
@Service
public class GoogleTokenInfoVerifier implements GoogleTokenVerifier {

    private static final String TOKENINFO_URL = "https://oauth2.googleapis.com/tokeninfo?id_token=";

    private final Set<String> allowedClientIds;
    private final HttpClient httpClient;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public GoogleTokenInfoVerifier(
            @Value("${app.google.client-ids:}") String clientIds) {
        this.allowedClientIds = Arrays.stream(clientIds.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .collect(Collectors.toCollection(HashSet::new));
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(8))
                .build();
    }

    @Override
    public GoogleUserInfo verify(String idToken) {
        if (allowedClientIds.isEmpty()) {
            log.error("Google login is not configured (app.google.client-ids is empty)");
            throw new BusinessException(
                    "Đăng nhập Google chưa được cấu hình trên máy chủ",
                    HttpStatus.INTERNAL_SERVER_ERROR);
        }

        JsonNode payload = fetchTokenInfo(idToken);

        String aud = payload.path("aud").asText(null);
        if (aud == null || !allowedClientIds.contains(aud)) {
            log.warn("Google token rejected: audience '{}' not in allowed client IDs", aud);
            throw invalidToken();
        }

        String email = payload.path("email").asText(null);
        if (email == null || email.isBlank()) {
            throw invalidToken();
        }
        boolean emailVerified = parseBoolean(payload.path("email_verified").asText("false"));

        return new GoogleUserInfo(
                payload.path("sub").asText(null),
                email,
                emailVerified,
                payload.path("name").asText(null),
                payload.path("picture").asText(null));
    }

    private JsonNode fetchTokenInfo(String idToken) {
        try {
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(TOKENINFO_URL
                            + URLEncoder.encode(idToken, StandardCharsets.UTF_8)))
                    .timeout(Duration.ofSeconds(8))
                    .GET()
                    .build();
            HttpResponse<String> response =
                    httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() != 200) {
                log.warn("Google tokeninfo returned status {}", response.statusCode());
                throw invalidToken();
            }
            return objectMapper.readTree(response.body());
        } catch (BusinessException ex) {
            throw ex;
        } catch (InterruptedException ex) {
            Thread.currentThread().interrupt();
            throw new BusinessException(
                    "Không xác thực được Google, vui lòng thử lại", HttpStatus.BAD_GATEWAY);
        } catch (Exception ex) {
            log.error("Failed to verify Google token: {}", ex.getMessage());
            throw new BusinessException(
                    "Không xác thực được Google, vui lòng thử lại", HttpStatus.BAD_GATEWAY);
        }
    }

    private boolean parseBoolean(String value) {
        return "true".equalsIgnoreCase(value) || "1".equals(value);
    }

    private BusinessException invalidToken() {
        return new BusinessException("Token Google không hợp lệ", HttpStatus.UNAUTHORIZED);
    }
}
