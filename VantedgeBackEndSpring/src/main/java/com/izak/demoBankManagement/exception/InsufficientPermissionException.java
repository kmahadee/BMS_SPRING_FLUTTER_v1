package com.izak.demoBankManagement.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

/**
 * Exception thrown when a user attempts to perform an operation they don't have permission for.
 * This is used for permission-based access control failures.
 */
@ResponseStatus(HttpStatus.FORBIDDEN)
public class InsufficientPermissionException extends RuntimeException {
    public InsufficientPermissionException(String message) {
        super(message);
    }
}
