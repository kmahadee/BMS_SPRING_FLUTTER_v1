package com.izak.demoBankManagement.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * DTO for listing pending user approvals
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PendingUserResponseDTO {

    private Long id;
    private String username;
    private String email;
    private String role;
    private String userStatus;
    private String branchCode;
    private String branchName;
    private LocalDateTime createdDate;
    private String approvalReason;
}
