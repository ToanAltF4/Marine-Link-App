package com.marinelink.common.exception;

import org.springframework.http.HttpStatus;

/**
 * Base business exception that maps to a specific HTTP status code.
 * Subclasses represent domain-level errors thrown from the service layer.
 */
public class BusinessException extends RuntimeException {

    private final HttpStatus status;

    public BusinessException(String message, HttpStatus status) {
        super(message);
        this.status = status;
    }

    public BusinessException(String message) {
        super(message);
        this.status = HttpStatus.UNPROCESSABLE_ENTITY; // 422 default
    }

    public HttpStatus getStatus() {
        return status;
    }
}
