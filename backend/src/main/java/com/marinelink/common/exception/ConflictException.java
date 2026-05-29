package com.marinelink.common.exception;

import org.springframework.http.HttpStatus;

/** Thrown when a state transition or duplicate-key conflict occurs. Maps to 409. */
public class ConflictException extends BusinessException {
    public ConflictException(String message) {
        super(message, HttpStatus.CONFLICT);
    }
}
