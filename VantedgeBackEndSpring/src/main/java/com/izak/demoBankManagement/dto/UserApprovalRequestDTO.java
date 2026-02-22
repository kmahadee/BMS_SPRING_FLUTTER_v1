package com.izak.demoBankManagement.dto;

import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO for admin approval/rejection workflow
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserApprovalRequestDTO {

    @NotNull(message = "User ID is required")
    private Long userId;

    @NotBlank(message = "Action is required")
    @Pattern(regexp = "APPROVE|REJECT", message = "Action must be either APPROVE or REJECT")
    private String action;

    @Size(max = 500, message = "Reason cannot exceed 500 characters")
    private String reason;

    @Pattern(regexp = "SUPER_ADMIN|ADMIN|CUSTOMER|EMPLOYEE|BRANCH_MANAGER|LOAN_OFFICER|CARD_OFFICER",
            message = "Invalid role")
    private String assignedRole; // Optional: Override role during approval

    @Size(max = 20, message = "Branch code cannot exceed 20 characters")
    private String branchCode; // Optional: Assign branch during approval
}
