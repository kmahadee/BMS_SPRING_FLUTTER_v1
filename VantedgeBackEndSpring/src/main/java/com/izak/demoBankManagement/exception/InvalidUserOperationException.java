package com.izak.demoBankManagement.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

/**
 * Exception thrown when an invalid user operation is attempted.
 * This includes invalid state transitions, invalid updates, or business rule violations.
 */
@ResponseStatus(HttpStatus.BAD_REQUEST)
public class InvalidUserOperationException extends RuntimeException {
    public InvalidUserOperationException(String message) {
        super(message);
    }
}
