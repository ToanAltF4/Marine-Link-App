package com.marinelink.common.api;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Builder;
import lombok.Getter;

import java.util.List;

/**
 * Unified API response envelope for all endpoints.
 *
 * <p>Success: {@code success=true}, {@code data} populated, {@code errors} null.
 * <p>Error: {@code success=false}, {@code data} null, {@code message} and {@code errors} populated.
 */
@Getter
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ApiResponse<T> {

    private final boolean success;
    private final String message;
    private final T data;
    private final List<FieldError> errors;
    private final PaginationMeta pagination;

    // ── Static factories ──────────────────────────────────────────────────────

    public static <T> ApiResponse<T> ok(T data) {
        return ApiResponse.<T>builder()
                .success(true)
                .message("OK")
                .data(data)
                .build();
    }

    public static <T> ApiResponse<T> ok(T data, String message) {
        return ApiResponse.<T>builder()
                .success(true)
                .message(message)
                .data(data)
                .build();
    }

    public static <T> ApiResponse<T> ok(T data, PaginationMeta pagination) {
        return ApiResponse.<T>builder()
                .success(true)
                .message("OK")
                .data(data)
                .pagination(pagination)
                .build();
    }

    public static <T> ApiResponse<T> created(T data, String message) {
        return ApiResponse.<T>builder()
                .success(true)
                .message(message)
                .data(data)
                .build();
    }

    public static <T> ApiResponse<T> error(String message) {
        return ApiResponse.<T>builder()
                .success(false)
                .message(message)
                .build();
    }

    public static <T> ApiResponse<T> error(String message, List<FieldError> errors) {
        return ApiResponse.<T>builder()
                .success(false)
                .message(message)
                .errors(errors)
                .build();
    }

    // ── Nested types ─────────────────────────────────────────────────────────

    @Getter
    @Builder
    public static class FieldError {
        private final String field;
        private final String message;
    }

    @Getter
    @Builder
    public static class PaginationMeta {
        private final int page;
        private final int size;
        private final long totalElements;
        private final int totalPages;

        public static PaginationMeta of(org.springframework.data.domain.Page<?> page) {
            return PaginationMeta.builder()
                    .page(page.getNumber())
                    .size(page.getSize())
                    .totalElements(page.getTotalElements())
                    .totalPages(page.getTotalPages())
                    .build();
        }
    }
}
