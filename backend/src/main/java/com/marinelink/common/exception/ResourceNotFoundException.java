package com.marinelink.common.exception;

import org.springframework.http.HttpStatus;

/** Thrown when a requested resource is not found or the caller is not allowed to see it. */
public class ResourceNotFoundException extends BusinessException {
    public ResourceNotFoundException(String message) {
        super(message, HttpStatus.NOT_FOUND);
    }
}
