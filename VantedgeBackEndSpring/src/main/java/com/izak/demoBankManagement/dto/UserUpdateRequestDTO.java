package com.izak.demoBankManagement.dto;

import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO for admin updates to user profile
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserUpdateRequestDTO {

    @Email(message = "Invalid email format")
    @Size(max = 100, message = "Email cannot exceed 100 characters")
    private String email;

    @Pattern(regexp = "SUPER_ADMIN|ADMIN|CUSTOMER|EMPLOYEE|BRANCH_MANAGER|LOAN_OFFICER|CARD_OFFICER",
            message = "Invalid role")
    private String role;

    @Pattern(regexp = "PENDING|ACTIVE|INACTIVE", message = "Invalid user status")
    private String userStatus;

    private Boolean isActive;

    private Boolean mustChangePassword;

    @Size(max = 20, message = "Branch code cannot exceed 20 characters")
    private String branchCode;
}
