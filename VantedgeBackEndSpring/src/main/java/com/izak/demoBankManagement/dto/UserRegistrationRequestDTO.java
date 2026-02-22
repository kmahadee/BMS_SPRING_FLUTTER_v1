package com.izak.demoBankManagement.dto;

import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO for user self-registration
 * Note: Role is restricted to CUSTOMER or EMPLOYEE during registration
 * Higher roles (ADMIN, SUPER_ADMIN) must be assigned by administrators
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserRegistrationRequestDTO {

    @NotBlank(message = "Username is required")
    @Size(min = 4, max = 50, message = "Username must be between 4 and 50 characters")
    private String username;

    @NotBlank(message = "Password is required")
    @Size(min = 6, message = "Password must be at least 6 characters")
    private String password;

    @NotBlank(message = "Email is required")
    @Email(message = "Invalid email format")
    @Size(max = 100, message = "Email cannot exceed 100 characters")
    private String email;

    @NotBlank(message = "Role is required")
    @Pattern(regexp = "CUSTOMER|EMPLOYEE", message = "Role must be either CUSTOMER or EMPLOYEE")
    private String role;

    @Size(max = 20, message = "Branch code cannot exceed 20 characters")
    private String branchCode; // Required for EMPLOYEE role
}
