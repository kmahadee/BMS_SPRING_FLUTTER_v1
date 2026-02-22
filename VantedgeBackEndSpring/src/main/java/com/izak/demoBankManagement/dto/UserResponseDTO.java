package com.izak.demoBankManagement.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * DTO for returning user details
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserResponseDTO {

    private Long id;
    private String username;
    private String email;
    private String role;
    private String userStatus;
    private Boolean isActive;
    private Boolean mustChangePassword;

    private Long branchId;
    private String branchCode;
    private String branchName;

    private String approvalReason;
    private String approvedBy;
    private LocalDateTime approvedDate;

    private LocalDateTime createdDate;
    private LocalDateTime lastModified;
}
