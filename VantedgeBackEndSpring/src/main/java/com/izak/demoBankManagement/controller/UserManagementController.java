package com.izak.demoBankManagement.controller;

import com.izak.demoBankManagement.dto.*;
import com.izak.demoBankManagement.service.UserManagementService;
import com.izak.demoBankManagement.security.JwtUtil;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * REST Controller for User Management operations
 *
 * Provides endpoints for:
 * - User registration and approval workflow
 * - User profile management
 * - Password management and reset
 * - Role and branch assignment
 * - User activation/deactivation
 * - User queries and listing
 *
 * Access control is enforced through:
 * - Public endpoints for registration
 * - Authenticated endpoints for self-service operations
 * - Admin-only endpoints for management operations
 * - SUPER_ADMIN hierarchy for elevated permissions
 */
@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
@Validated
@Slf4j
@CrossOrigin(origins = "http://localhost:4200")
@Tag(name = "User Management", description = "APIs for user management operations")
public class UserManagementController {

    private final UserManagementService userManagementService;
    private final JwtUtil jwtUtil;

    // ============================================================================
    // PUBLIC ENDPOINTS (No Authentication Required)
    // ============================================================================

    /**
     * Register a new user account
     *
     * Allows self-registration for CUSTOMER and EMPLOYEE roles only.
     * Higher roles (ADMIN, SUPER_ADMIN) must be assigned by administrators.
     * New users are created with PENDING status and require admin approval.
     *
     * @param request User registration details
     * @return Created user details
     */
    @PostMapping("/register")
    @Operation(summary = "Register new user",
            description = "Self-registration for CUSTOMER and EMPLOYEE roles. Higher roles require admin assignment.")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "201", description = "User registered successfully"),
            @ApiResponse(responseCode = "400", description = "Invalid input or validation error"),
            @ApiResponse(responseCode = "409", description = "Username or email already exists")
    })
    public ResponseEntity<com.izak.demoBankManagement.dto.ApiResponse<UserResponseDTO>> registerUser(
            @Valid @RequestBody UserRegistrationRequestDTO request) {
        log.info("User registration request for username: {}", request.getUsername());

        UserResponseDTO response = userManagementService.registerUser(request);

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(com.izak.demoBankManagement.dto.ApiResponse.success(
                        "User registration successful. Account pending approval.", response));
    }

    // ============================================================================
    // AUTHENTICATED USER ENDPOINTS (All Authenticated Users)
    // ============================================================================

    /**
     * Change current user's password
     *
     * Allows any authenticated user to change their own password.
     * Validates current password, ensures new password differs from current,
     * and enforces password requirements.
     *
     * @param authHeader Authorization header containing JWT token
     * @param request Password change request with current and new passwords
     * @return Success message
     */
    @PostMapping("/change-password")
    @Operation(summary = "Change password",
            description = "Change current user's password. Requires current password verification.")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Password changed successfully"),
            @ApiResponse(responseCode = "400", description = "Invalid password or validation error"),
            @ApiResponse(responseCode = "401", description = "Unauthorized - invalid token")
    })
    public ResponseEntity<com.izak.demoBankManagement.dto.ApiResponse<String>> changePassword(
            @RequestHeader("Authorization") String authHeader,
            @Valid @RequestBody PasswordChangeRequestDTO request) {

        String username = extractUsername(authHeader);
        log.info("Password change request for user: {}", username);

        String result = userManagementService.changePassword(username, request);

        return ResponseEntity.ok(
                com.izak.demoBankManagement.dto.ApiResponse.success(result, null));
    }

    /**
     * Get current user's profile
     *
     * Returns the profile information of the currently authenticated user.
     *
     * @param authHeader Authorization header containing JWT token
     * @return Current user's profile details
     */
    @GetMapping("/me")
    @Operation(summary = "Get current user profile",
            description = "Retrieve profile information of the authenticated user")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "User profile retrieved successfully"),
            @ApiResponse(responseCode = "401", description = "Unauthorized - invalid token"),
            @ApiResponse(responseCode = "404", description = "User not found")
    })
    public ResponseEntity<com.izak.demoBankManagement.dto.ApiResponse<UserResponseDTO>> getCurrentUser(
            @RequestHeader("Authorization") String authHeader) {

        String username = extractUsername(authHeader);
        log.info("Get current user profile request for: {}", username);

        // Get user by username through repository lookup
        UserResponseDTO user = userManagementService.getUserByUsername(username);

        return ResponseEntity.ok(
                com.izak.demoBankManagement.dto.ApiResponse.success(
                        "User profile retrieved successfully", user));
    }

    // ============================================================================
    // ADMIN ENDPOINTS (ADMIN and SUPER_ADMIN only)
    // ============================================================================

    /**
     * Get all users or filter by role
     *
     * Retrieves all users in the system. Optionally filter by role.
     *
     * @param role Optional role filter (e.g., "ADMIN", "CUSTOMER")
     * @return List of users
     */
    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPER_ADMIN')")
    @Operation(summary = "Get all users",
            description = "Retrieve all users or filter by role. Admin access required.")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Users retrieved successfully"),
            @ApiResponse(responseCode = "401", description = "Unauthorized"),
            @ApiResponse(responseCode = "403", description = "Forbidden - insufficient permissions")
    })
    public ResponseEntity<com.izak.demoBankManagement.dto.ApiResponse<List<UserResponseDTO>>> getAllUsers(
            @RequestParam(required = false) String role) {

        log.info("Get all users request with role filter: {}", role);

        List<UserResponseDTO> users;
        if (role != null && !role.trim().isEmpty()) {
            users = userManagementService.getUsersByRole(role);
            log.info("Retrieved {} users with role: {}", users.size(), role);
        } else {
            users = userManagementService.getAllUsers();
            log.info("Retrieved {} users", users.size());
        }

        return ResponseEntity.ok(
                com.izak.demoBankManagement.dto.ApiResponse.success(
                        "Users retrieved successfully", users));
    }

    /**
     * Get user by ID
     *
     * @param id User ID
     * @return User details
     */
    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPER_ADMIN')")
    @Operation(summary = "Get user by ID",
            description = "Retrieve user details by user ID. Admin access required.")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "User retrieved successfully"),
            @ApiResponse(responseCode = "401", description = "Unauthorized"),
            @ApiResponse(responseCode = "403", description = "Forbidden - insufficient permissions"),
            @ApiResponse(responseCode = "404", description = "User not found")
    })
    public ResponseEntity<com.izak.demoBankManagement.dto.ApiResponse<UserResponseDTO>> getUserById(
            @PathVariable Long id) {

        log.info("Get user by ID request: {}", id);

        UserResponseDTO user = userManagementService.getUserById(id);

        return ResponseEntity.ok(
                com.izak.demoBankManagement.dto.ApiResponse.success(
                        "User retrieved successfully", user));
    }

    /**
     * Get all pending user approvals
     *
     * Retrieves all users with PENDING status awaiting admin approval.
     *
     * @return List of pending users
     */
    @GetMapping("/pending")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPER_ADMIN')")
    @Operation(summary = "Get pending approvals",
            description = "Retrieve all users pending approval. Admin access required.")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Pending users retrieved successfully"),
            @ApiResponse(responseCode = "401", description = "Unauthorized"),
            @ApiResponse(responseCode = "403", description = "Forbidden - insufficient permissions")
    })
    public ResponseEntity<com.izak.demoBankManagement.dto.ApiResponse<List<PendingUserResponseDTO>>> getPendingApprovals() {
        log.info("Get pending user approvals request");

        List<PendingUserResponseDTO> pendingUsers = userManagementService.getPendingApprovals();

        return ResponseEntity.ok(
                com.izak.demoBankManagement.dto.ApiResponse.success(
                        "Pending approvals retrieved successfully", pendingUsers));
    }

    /**
     * Approve a pending user
     *
     * Approves a user registration and activates their account.
     * Can optionally override role and assign branch during approval.
     *
     * @param authHeader Authorization header containing JWT token
     * @param id User ID to approve
     * @param request Approval details with optional role/branch assignment
     * @return Approved user details
     */
    @PostMapping("/{id}/approve")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPER_ADMIN')")
    @Operation(summary = "Approve user",
            description = "Approve pending user registration. Can override role and assign branch.")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "User approved successfully"),
            @ApiResponse(responseCode = "400", description = "Invalid request or user not in PENDING status"),
            @ApiResponse(responseCode = "401", description = "Unauthorized"),
            @ApiResponse(responseCode = "403", description = "Forbidden - insufficient permissions"),
            @ApiResponse(responseCode = "404", description = "User not found")
    })
    public ResponseEntity<com.izak.demoBankManagement.dto.ApiResponse<UserResponseDTO>> approveUser(
            @RequestHeader("Authorization") String authHeader,
            @PathVariable Long id,
            @Valid @RequestBody UserApprovalRequestDTO request) {

        String adminUsername = extractUsername(authHeader);
        log.info("Admin {} approving user ID: {}", adminUsername, id);

        // Set userId from path variable
        request.setUserId(id);

        UserResponseDTO response = userManagementService.approveUser(adminUsername, request);

        return ResponseEntity.ok(
                com.izak.demoBankManagement.dto.ApiResponse.success(
                        "User approved successfully", response));
    }

    /**
     * Reject a pending user
     *
     * Rejects a user registration request.
     *
     * @param authHeader Authorization header containing JWT token
     * @param id User ID to reject
     * @param reason Reason for rejection
     * @return Success message
     */
    @PostMapping("/{id}/reject")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPER_ADMIN')")
    @Operation(summary = "Reject user",
            description = "Reject pending user registration with reason.")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "User rejected successfully"),
            @ApiResponse(responseCode = "400", description = "Invalid request or user not in PENDING status"),
            @ApiResponse(responseCode = "401", description = "Unauthorized"),
            @ApiResponse(responseCode = "403", description = "Forbidden - insufficient permissions"),
            @ApiResponse(responseCode = "404", description = "User not found")
    })
    public ResponseEntity<com.izak.demoBankManagement.dto.ApiResponse<Void>> rejectUser(
            @RequestHeader("Authorization") String authHeader,
            @PathVariable Long id,
            @RequestParam String reason) {

        String adminUsername = extractUsername(authHeader);
        log.info("Admin {} rejecting user ID: {} with reason: {}", adminUsername, id, reason);

        userManagementService.rejectUser(adminUsername, id, reason);

        return ResponseEntity.ok(
                com.izak.demoBankManagement.dto.ApiResponse.success(
                        "User rejected successfully", null));
    }

    /**
     * Update user role
     *
     * Updates a user's role. Enforces permission hierarchy:
     * - SUPER_ADMIN can modify any user
     * - ADMIN can modify users below ADMIN level
     *
     * @param authHeader Authorization header containing JWT token
     * @param id User ID
     * @param role New role
     * @return Updated user details
     */
    @PutMapping("/{id}/role")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPER_ADMIN')")
    @Operation(summary = "Update user role",
            description = "Change user role. Enforces permission hierarchy.")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "User role updated successfully"),
            @ApiResponse(responseCode = "400", description = "Invalid role or missing required branch"),
            @ApiResponse(responseCode = "401", description = "Unauthorized"),
            @ApiResponse(responseCode = "403", description = "Forbidden - insufficient permissions"),
            @ApiResponse(responseCode = "404", description = "User not found")
    })
    public ResponseEntity<com.izak.demoBankManagement.dto.ApiResponse<UserResponseDTO>> updateUserRole(
            @RequestHeader("Authorization") String authHeader,
            @PathVariable Long id,
            @RequestParam String role) {

        String adminUsername = extractUsername(authHeader);
        log.info("Admin {} updating role for user ID: {} to role: {}", adminUsername, id, role);

        UserResponseDTO response = userManagementService.updateUserRole(adminUsername, id, role);

        return ResponseEntity.ok(
                com.izak.demoBankManagement.dto.ApiResponse.success(
                        "User role updated successfully", response));
    }

    /**
     * Update user branch assignment
     *
     * Assigns or updates the branch for a user.
     * Validates that the role requires branch assignment.
     *
     * @param authHeader Authorization header containing JWT token
     * @param id User ID
     * @param branchId Branch ID to assign
     * @return Updated user details
     */
    @PutMapping("/{id}/branch")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPER_ADMIN')")
    @Operation(summary = "Update user branch",
            description = "Assign or update user's branch assignment.")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "User branch updated successfully"),
            @ApiResponse(responseCode = "400", description = "Invalid branch assignment for role"),
            @ApiResponse(responseCode = "401", description = "Unauthorized"),
            @ApiResponse(responseCode = "403", description = "Forbidden - insufficient permissions"),
            @ApiResponse(responseCode = "404", description = "User or branch not found")
    })
    public ResponseEntity<com.izak.demoBankManagement.dto.ApiResponse<UserResponseDTO>> updateUserBranch(
            @RequestHeader("Authorization") String authHeader,
            @PathVariable Long id,
            @RequestParam Long branchId) {

        String adminUsername = extractUsername(authHeader);
        log.info("Admin {} updating branch for user ID: {} to branch ID: {}",
                adminUsername, id, branchId);

        UserResponseDTO response = userManagementService.updateBranchId(adminUsername, id, branchId);

        return ResponseEntity.ok(
                com.izak.demoBankManagement.dto.ApiResponse.success(
                        "User branch updated successfully", response));
    }

    /**
     * Update user details
     *
     * Updates various user profile fields.
     * Enforces permission hierarchy for modifications.
     *
     * @param authHeader Authorization header containing JWT token
     * @param id User ID
     * @param request Update request with new values
     * @return Updated user details
     */
    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPER_ADMIN')")
    @Operation(summary = "Update user",
            description = "Update user profile details. Admin access required.")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "User updated successfully"),
            @ApiResponse(responseCode = "400", description = "Invalid input or validation error"),
            @ApiResponse(responseCode = "401", description = "Unauthorized"),
            @ApiResponse(responseCode = "403", description = "Forbidden - insufficient permissions"),
            @ApiResponse(responseCode = "404", description = "User not found"),
            @ApiResponse(responseCode = "409", description = "Email already exists")
    })
    public ResponseEntity<com.izak.demoBankManagement.dto.ApiResponse<UserResponseDTO>> updateUser(
            @RequestHeader("Authorization") String authHeader,
            @PathVariable Long id,
            @Valid @RequestBody UserUpdateRequestDTO request) {

        String adminUsername = extractUsername(authHeader);
        log.info("Admin {} updating user ID: {}", adminUsername, id);

        UserResponseDTO response = userManagementService.updateUser(id, request);

        return ResponseEntity.ok(
                com.izak.demoBankManagement.dto.ApiResponse.success(
                        "User updated successfully", response));
    }

    /**
     * Reset user password
     *
     * Generates a temporary password for the user.
     * User will be required to change password on next login.
     *
     * SECURITY WARNING: Returns plaintext temporary password.
     * Must be communicated securely to the user.
     *
     * @param authHeader Authorization header containing JWT token
     * @param id User ID
     * @return Temporary password (plaintext)
     */
    @PostMapping("/{id}/reset-password")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPER_ADMIN')")
    @Operation(summary = "Reset user password",
            description = "Generate temporary password for user. Returns plaintext password.")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Password reset successfully"),
            @ApiResponse(responseCode = "401", description = "Unauthorized"),
            @ApiResponse(responseCode = "403", description = "Forbidden - insufficient permissions"),
            @ApiResponse(responseCode = "404", description = "User not found")
    })
    public ResponseEntity<com.izak.demoBankManagement.dto.ApiResponse<String>> resetPassword(
            @RequestHeader("Authorization") String authHeader,
            @PathVariable Long id) {

        String adminUsername = extractUsername(authHeader);
        log.info("Admin {} requesting password reset for user ID: {}", adminUsername, id);

        String temporaryPassword = userManagementService.resetUserPassword(adminUsername, id);

        return ResponseEntity.ok(
                com.izak.demoBankManagement.dto.ApiResponse.success(
                        "Password reset successfully. Temporary password generated.",
                        temporaryPassword));
    }

    /**
     * Deactivate user account
     *
     * Deactivates a user account, preventing login.
     * Cannot deactivate SUPER_ADMIN or last active ADMIN.
     * Cannot deactivate own account.
     *
     * @param authHeader Authorization header containing JWT token
     * @param id User ID
     * @return Success message
     */
    @PostMapping("/{id}/deactivate")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPER_ADMIN')")
    @Operation(summary = "Deactivate user",
            description = "Deactivate user account. Cannot deactivate SUPER_ADMIN or self.")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "User deactivated successfully"),
            @ApiResponse(responseCode = "400", description = "Cannot deactivate this user"),
            @ApiResponse(responseCode = "401", description = "Unauthorized"),
            @ApiResponse(responseCode = "403", description = "Forbidden - insufficient permissions"),
            @ApiResponse(responseCode = "404", description = "User not found")
    })
    public ResponseEntity<com.izak.demoBankManagement.dto.ApiResponse<Void>> deactivateUser(
            @RequestHeader("Authorization") String authHeader,
            @PathVariable Long id) {

        String adminUsername = extractUsername(authHeader);
        log.info("Admin {} deactivating user ID: {}", adminUsername, id);

        userManagementService.deactivateUser(adminUsername, id);

        return ResponseEntity.ok(
                com.izak.demoBankManagement.dto.ApiResponse.success(
                        "User deactivated successfully", null));
    }

    /**
     * Reactivate user account
     *
     * Reactivates a previously deactivated user account.
     *
     * @param authHeader Authorization header containing JWT token
     * @param id User ID
     * @return Reactivated user details
     */
    @PostMapping("/{id}/reactivate")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPER_ADMIN')")
    @Operation(summary = "Reactivate user",
            description = "Reactivate a deactivated user account.")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "User reactivated successfully"),
            @ApiResponse(responseCode = "401", description = "Unauthorized"),
            @ApiResponse(responseCode = "403", description = "Forbidden - insufficient permissions"),
            @ApiResponse(responseCode = "404", description = "User not found")
    })
    public ResponseEntity<com.izak.demoBankManagement.dto.ApiResponse<UserResponseDTO>> reactivateUser(
            @RequestHeader("Authorization") String authHeader,
            @PathVariable Long id) {

        String adminUsername = extractUsername(authHeader);
        log.info("Admin {} reactivating user ID: {}", adminUsername, id);

        UserResponseDTO response = userManagementService.reactivateUser(adminUsername, id);

        return ResponseEntity.ok(
                com.izak.demoBankManagement.dto.ApiResponse.success(
                        "User reactivated successfully", response));
    }

    /**
     * Get users by branch
     *
     * Retrieves all users assigned to a specific branch.
     *
     * @param branchId Branch ID
     * @return List of users in the branch
     */
    @GetMapping("/branch/{branchId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPER_ADMIN', 'BRANCH_MANAGER')")
    @Operation(summary = "Get users by branch",
            description = "Retrieve all users assigned to a specific branch.")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Users retrieved successfully"),
            @ApiResponse(responseCode = "401", description = "Unauthorized"),
            @ApiResponse(responseCode = "403", description = "Forbidden - insufficient permissions"),
            @ApiResponse(responseCode = "404", description = "Branch not found")
    })
    public ResponseEntity<com.izak.demoBankManagement.dto.ApiResponse<List<UserResponseDTO>>> getUsersByBranch(
            @PathVariable Long branchId) {

        log.info("Get users by branch ID request: {}", branchId);

        List<UserResponseDTO> users = userManagementService.getUsersByBranch(branchId);

        return ResponseEntity.ok(
                com.izak.demoBankManagement.dto.ApiResponse.success(
                        "Users retrieved successfully", users));
    }

    // ============================================================================
    // HELPER METHODS
    // ============================================================================

    /**
     * Extract username from Authorization header
     *
     * Removes "Bearer " prefix and extracts username from JWT token.
     *
     * @param authHeader Authorization header value (format: "Bearer {token}")
     * @return Username from token
     */
    private String extractUsername(String authHeader) {
        String jwt = authHeader.substring(7); // Remove "Bearer " prefix
        return jwtUtil.extractUsername(jwt);
    }
}