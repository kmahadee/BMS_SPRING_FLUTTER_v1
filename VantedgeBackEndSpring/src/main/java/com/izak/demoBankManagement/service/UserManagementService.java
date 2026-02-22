package com.izak.demoBankManagement.service;

import com.izak.demoBankManagement.dto.*;
import com.izak.demoBankManagement.entity.Branch;
import com.izak.demoBankManagement.entity.Customer;
import com.izak.demoBankManagement.entity.User;
import com.izak.demoBankManagement.exception.*;
import com.izak.demoBankManagement.repository.BranchRepository;
import com.izak.demoBankManagement.repository.CustomerRepository;
import com.izak.demoBankManagement.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Random;
import java.util.stream.Collectors;

/**
 * Service for managing user accounts and approval workflows.
 * Handles user registration, approval/rejection, password management, and user queries.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class UserManagementService {

    private final UserRepository userRepository;
    private final BranchRepository branchRepository;
    private final CustomerRepository customerRepository;
    private final PasswordEncoder passwordEncoder;
    private final BranchAuthorizationService branchAuthorizationService;

    // ============================================================================
    // EXISTING METHODS (from original UserManagementService)
    // ============================================================================

    /**
     * Register a new user with PENDING status
     * Only CUSTOMER and EMPLOYEE roles are allowed for self-registration
     * Higher roles (ADMIN, SUPER_ADMIN) must be assigned by administrators
     *
     * @param request User registration details
     * @return UserResponseDTO with created user details
     * @throws UserAlreadyExistsException if username or email already exists
     * @throws InvalidUserOperationException if invalid role or missing branch for EMPLOYEE
     * @throws ResourceNotFoundException if branch not found
     */
    @Transactional
    public UserResponseDTO registerUser(UserRegistrationRequestDTO request) {
        log.info("Registering new user: {}", request.getUsername());

        // Validate username uniqueness
        if (userRepository.existsByUsername(request.getUsername())) {
            log.warn("Username already exists: {}", request.getUsername());
            throw new UserAlreadyExistsException("Username already exists: " + request.getUsername());
        }

        // Validate email uniqueness
        if (userRepository.existsByEmail(request.getEmail())) {
            log.warn("Email already exists: {}", request.getEmail());
            throw new UserAlreadyExistsException("Email already exists: " + request.getEmail());
        }

        // Validate role restriction for self-registration
        User.Role role;
        try {
            role = User.Role.valueOf(request.getRole().toUpperCase());
        } catch (IllegalArgumentException e) {
            log.error("Invalid role: {}", request.getRole());
            throw new InvalidUserOperationException("Invalid role: " + request.getRole());
        }

        if (role != User.Role.CUSTOMER && role != User.Role.EMPLOYEE) {
            log.warn("Attempted self-registration with restricted role: {}", role);
            throw new InvalidUserOperationException(
                    "Self-registration is only allowed for CUSTOMER and EMPLOYEE roles. " +
                            "Higher roles must be assigned by administrators.");
        }

        // Create new user
        User user = new User();
        user.setUsername(request.getUsername());
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        user.setEmail(request.getEmail());
        user.setRole(role);
        user.setUserStatus(User.UserStatus.PENDING); // Default to PENDING for approval workflow
        user.setIsActive(false); // Inactive until approved
        user.setMustChangePassword(false);

        // Handle branch assignment for EMPLOYEE role
        if (role == User.Role.EMPLOYEE) {
            if (request.getBranchCode() != null && !request.getBranchCode().trim().isEmpty()) {
                Branch branch = branchRepository.findByBranchCode(request.getBranchCode())
                        .orElseThrow(() -> new ResourceNotFoundException(
                                "Branch not found with code: " + request.getBranchCode()));

                if (branch.getStatus() != Branch.BranchStatus.ACTIVE) {
                    log.warn("Attempted to assign user to inactive branch: {}", request.getBranchCode());
                    throw new InvalidUserOperationException(
                            "Cannot assign user to inactive branch: " + request.getBranchCode());
                }

                user.setBranch(branch);
                log.info("Assigned user {} to branch {}", request.getUsername(), branch.getBranchCode());
            } else {
                log.info("EMPLOYEE registration without branch assignment - will require admin assignment");
            }
        }

        user = userRepository.save(user);

        log.info("User registered successfully: {} with status PENDING", user.getUsername());

        return mapToResponseDTO(user);
    }

    /**
     * Get all users with PENDING status awaiting approval
     *
     * @return List of pending users
     */
    @Transactional(readOnly = true)
    public List<PendingUserResponseDTO> getPendingApprovals() {
        log.info("Fetching all pending user approvals");

        List<User> pendingUsers = userRepository.findByUserStatus(User.UserStatus.PENDING);

        log.info("Found {} pending user approvals", pendingUsers.size());

        return pendingUsers.stream()
                .map(this::mapToPendingUserDTO)
                .collect(Collectors.toList());
    }

    /**
     * Approve a pending user and activate their account
     * Can optionally override role and assign branch during approval
     * FIXED: Now properly creates Customer entity for CUSTOMER role users
     *
     * @param adminUsername Username of the approving administrator
     * @param request Approval request with optional role/branch assignment
     * @return UserResponseDTO with updated user details
     * @throws UserNotFoundException if user not found
     * @throws InvalidUserOperationException if user not in PENDING status or invalid role/branch
     * @throws ResourceNotFoundException if branch not found
     */
    @Transactional
    public UserResponseDTO approveUser(String adminUsername, UserApprovalRequestDTO request) {
        log.info("Admin {} approving user ID: {}", adminUsername, request.getUserId());

        User user = userRepository.findById(request.getUserId())
                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + request.getUserId()));

        if (user.getUserStatus() != User.UserStatus.PENDING) {
            log.warn("Attempted to approve user {} with status: {}", user.getUsername(), user.getUserStatus());
            throw new InvalidUserOperationException(
                    "User is not in PENDING status. Current status: " + user.getUserStatus());
        }

        // Override role if provided
        if (request.getAssignedRole() != null && !request.getAssignedRole().trim().isEmpty()) {
            try {
                User.Role newRole = User.Role.valueOf(request.getAssignedRole().toUpperCase());
                user.setRole(newRole);
                log.info("Role updated to {} during approval", newRole);
            } catch (IllegalArgumentException e) {
                log.error("Invalid assigned role: {}", request.getAssignedRole());
                throw new InvalidUserOperationException("Invalid role: " + request.getAssignedRole());
            }
        }

        // Assign or update branch if provided
        if (request.getBranchCode() != null && !request.getBranchCode().trim().isEmpty()) {
            Branch branch = branchRepository.findByBranchCode(request.getBranchCode())
                    .orElseThrow(() -> new ResourceNotFoundException(
                            "Branch not found with code: " + request.getBranchCode()));

            if (branch.getStatus() != Branch.BranchStatus.ACTIVE) {
                log.warn("Attempted to assign user to inactive branch: {}", request.getBranchCode());
                throw new InvalidUserOperationException(
                        "Cannot assign user to inactive branch: " + request.getBranchCode());
            }

            user.setBranch(branch);
            log.info("Branch assigned/updated to {} during approval", branch.getBranchCode());
        }

        // Validate branch assignment for certain roles
        if ((user.getRole() == User.Role.BRANCH_MANAGER ||
                user.getRole() == User.Role.LOAN_OFFICER ||
                user.getRole() == User.Role.CARD_OFFICER) && user.getBranch() == null) {
            log.warn("Attempted to approve {} without branch assignment", user.getRole());
            throw new InvalidUserOperationException(
                    user.getRole() + " must be assigned to a branch");
        }

        // Update approval fields BEFORE creating Customer (so user is saved with final state)
        user.setUserStatus(User.UserStatus.ACTIVE);
        user.setIsActive(true);
        user.setApprovedBy(adminUsername);
        user.setApprovedDate(LocalDateTime.now());
        user.setApprovalReason(request.getReason());

        user = userRepository.save(user);

        // ============================================================================
        // CRITICAL FIX: Create Customer entity for CUSTOMER role users
        // ============================================================================
        if (user.getRole() == User.Role.CUSTOMER) {
            // Store final userId for use in lambda
            final Long finalUserId = user.getId();

            // Check if Customer entity already exists for this user
            boolean customerExists = customerRepository.findAll().stream()
                    .anyMatch(c -> c.getUser() != null && c.getUser().getId().equals(finalUserId));

            if (!customerExists) {
                log.info("Creating Customer entity for approved CUSTOMER user: {}", user.getUsername());

                Customer customer = new Customer();
                customer.setUser(user);
                customer.setCustomerId(generateCustomerIdForApproval());
                customer.setEmail(user.getEmail());
                customer.setStatus(Customer.Status.ACTIVE);
                customer.setKycStatus(Customer.KycStatus.PENDING);

                // Note: firstName, lastName, phone, address, etc. are not available during approval
                // These will need to be filled in later by the customer or admin through profile update

                customerRepository.save(customer);
                log.info("Customer entity created successfully with ID: {} for user: {}",
                        customer.getCustomerId(), user.getUsername());
            } else {
                log.info("Customer entity already exists for user: {}", user.getUsername());
            }
        }
        // ============================================================================

        log.info("User {} approved successfully by {}", user.getUsername(), adminUsername);

        return mapToResponseDTO(user);
    }

    /**
     * Reject a pending user registration
     *
     * @param adminUsername Username of the rejecting administrator
     * @param userId User ID to reject
     * @param reason Reason for rejection
     * @throws UserNotFoundException if user not found
     * @throws InvalidUserOperationException if user not in PENDING status
     */
    @Transactional
    public void rejectUser(String adminUsername, Long userId, String reason) {
        log.info("Admin {} rejecting user ID: {}", adminUsername, userId);

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + userId));

        if (user.getUserStatus() != User.UserStatus.PENDING) {
            log.warn("Attempted to reject user {} with status: {}", user.getUsername(), user.getUserStatus());
            throw new InvalidUserOperationException(
                    "User is not in PENDING status. Current status: " + user.getUserStatus());
        }

        user.setUserStatus(User.UserStatus.INACTIVE);
        user.setIsActive(false);
        user.setApprovedBy(adminUsername);
        user.setApprovedDate(LocalDateTime.now());
        user.setApprovalReason(reason != null ? reason : "Registration rejected");

        userRepository.save(user);

        log.info("User {} rejected successfully by {}", user.getUsername(), adminUsername);
    }

    /**
     * Get user details by ID
     *
     * @param userId User ID
     * @return UserResponseDTO with user details
     * @throws UserNotFoundException if user not found
     */
    @Transactional(readOnly = true)
    public UserResponseDTO getUserById(Long userId) {
        log.info("Fetching user by ID: {}", userId);

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + userId));

        return mapToResponseDTO(user);
    }

    /**
     * Get all users in the system
     *
     * @return List of all users
     */
    @Transactional(readOnly = true)
    public List<UserResponseDTO> getAllUsers() {
        log.info("Fetching all users");

        List<User> users = userRepository.findAll();

        log.info("Retrieved {} users", users.size());

        return users.stream()
                .map(this::mapToResponseDTO)
                .collect(Collectors.toList());
    }

    /**
     * Get all users with a specific role
     *
     * @param role Role name (e.g., "ADMIN", "CUSTOMER")
     * @return List of users with the specified role
     * @throws InvalidUserOperationException if invalid role provided
     */
    @Transactional(readOnly = true)
    public List<UserResponseDTO> getUsersByRole(String role) {
        log.info("Fetching users by role: {}", role);

        User.Role userRole;
        try {
            userRole = User.Role.valueOf(role.toUpperCase());
        } catch (IllegalArgumentException e) {
            log.error("Invalid role: {}", role);
            throw new InvalidUserOperationException("Invalid role: " + role);
        }

        List<User> users = userRepository.findByRole(userRole);

        log.info("Retrieved {} users with role {}", users.size(), role);

        return users.stream()
                .map(this::mapToResponseDTO)
                .collect(Collectors.toList());
    }

    /**
     * Update user details (admin operation)
     *
     * @param userId User ID to update
     * @param request Update request with new values
     * @return Updated user details
     * @throws UserNotFoundException if user not found
     * @throws UserAlreadyExistsException if email already exists for another user
     * @throws InvalidUserOperationException if invalid role or branch
     * @throws ResourceNotFoundException if branch not found
     */
    @Transactional
    public UserResponseDTO updateUser(Long userId, UserUpdateRequestDTO request) {
        log.info("Updating user ID: {}", userId);

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + userId));

        // Update email if provided
        if (request.getEmail() != null && !request.getEmail().trim().isEmpty()) {
            if (!user.getEmail().equals(request.getEmail()) &&
                    userRepository.existsByEmail(request.getEmail())) {
                log.warn("Email already exists: {}", request.getEmail());
                throw new UserAlreadyExistsException("Email already exists: " + request.getEmail());
            }

            final String newEmail = request.getEmail();
            user.setEmail(newEmail);

            // Update Customer email if this is a CUSTOMER user
            if (user.getRole() == User.Role.CUSTOMER) {
                final Long finalUserId = user.getId();
                customerRepository.findAll().stream()
                        .filter(c -> c.getUser() != null && c.getUser().getId().equals(finalUserId))
                        .findFirst()
                        .ifPresent(customer -> {
                            customer.setEmail(newEmail);
                            customerRepository.save(customer);
                            log.info("Updated Customer email to match User email");
                        });
            }
        }

        // Update role if provided
        if (request.getRole() != null && !request.getRole().trim().isEmpty()) {
            try {
                User.Role newRole = User.Role.valueOf(request.getRole().toUpperCase());
                user.setRole(newRole);
                log.info("Role updated to {}", newRole);
            } catch (IllegalArgumentException e) {
                log.error("Invalid role: {}", request.getRole());
                throw new InvalidUserOperationException("Invalid role: " + request.getRole());
            }
        }

        // Update user status if provided
        if (request.getUserStatus() != null && !request.getUserStatus().trim().isEmpty()) {
            try {
                User.UserStatus newStatus = User.UserStatus.valueOf(request.getUserStatus().toUpperCase());
                user.setUserStatus(newStatus);
                log.info("User status updated to {}", newStatus);
            } catch (IllegalArgumentException e) {
                log.error("Invalid user status: {}", request.getUserStatus());
                throw new InvalidUserOperationException("Invalid user status: " + request.getUserStatus());
            }
        }

        // Update isActive if provided
        if (request.getIsActive() != null) {
            final Boolean newActiveStatus = request.getIsActive();
            user.setIsActive(newActiveStatus);

            // Update Customer status if this is a CUSTOMER user
            if (user.getRole() == User.Role.CUSTOMER) {
                final Long finalUserId = user.getId();
                customerRepository.findAll().stream()
                        .filter(c -> c.getUser() != null && c.getUser().getId().equals(finalUserId))
                        .findFirst()
                        .ifPresent(customer -> {
                            customer.setStatus(newActiveStatus ?
                                    Customer.Status.ACTIVE : Customer.Status.INACTIVE);
                            customerRepository.save(customer);
                            log.info("Updated Customer status to match User isActive status");
                        });
            }
        }

        // Update mustChangePassword if provided
        if (request.getMustChangePassword() != null) {
            user.setMustChangePassword(request.getMustChangePassword());
        }

        // Update branch if provided
        if (request.getBranchCode() != null && !request.getBranchCode().trim().isEmpty()) {
            Branch branch = branchRepository.findByBranchCode(request.getBranchCode())
                    .orElseThrow(() -> new ResourceNotFoundException(
                            "Branch not found with code: " + request.getBranchCode()));

            if (branch.getStatus() != Branch.BranchStatus.ACTIVE) {
                log.warn("Attempted to assign user to inactive branch: {}", request.getBranchCode());
                throw new InvalidUserOperationException(
                        "Cannot assign user to inactive branch: " + request.getBranchCode());
            }

            user.setBranch(branch);
            log.info("Branch updated to {}", branch.getBranchCode());
        }

        user = userRepository.save(user);

        log.info("User {} updated successfully", user.getUsername());

        return mapToResponseDTO(user);
    }

    /**
     * Change user password
     *
     * @param userId User ID
     * @param request Password change request
     * @throws UserNotFoundException if user not found
     * @throws InvalidUserOperationException if current password incorrect or passwords don't match
     */
    @Transactional
    public void changePassword(Long userId, PasswordChangeRequestDTO request) {
        log.info("Changing password for user ID: {}", userId);

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + userId));

        // Validate current password
        if (!passwordEncoder.matches(request.getCurrentPassword(), user.getPassword())) {
            log.warn("Invalid current password for user {}", user.getUsername());
            throw new InvalidUserOperationException("Current password is incorrect");
        }

        // Validate new password confirmation
        if (!request.getNewPassword().equals(request.getConfirmPassword())) {
            log.warn("New password and confirmation do not match for user {}", user.getUsername());
            throw new InvalidUserOperationException("New password and confirmation do not match");
        }

        // Validate new password is different from current
        if (passwordEncoder.matches(request.getNewPassword(), user.getPassword())) {
            log.warn("New password is same as current password for user {}", user.getUsername());
            throw new InvalidUserOperationException("New password must be different from current password");
        }

        // Update password
        user.setPassword(passwordEncoder.encode(request.getNewPassword()));
        user.setMustChangePassword(false);

        userRepository.save(user);

        log.info("Password changed successfully for user {}", user.getUsername());
    }

    // ============================================================================
    // NEW PASSWORD MANAGEMENT METHODS
    // ============================================================================

    /**
     * Change user password with enhanced security validations
     *
     * WARNING: This method handles sensitive password data. Ensure:
     * - Current password is verified before allowing change
     * - New password meets minimum requirements
     * - New password differs from current password
     * - Password is encoded before storage
     * - No plaintext passwords are logged
     *
     * @param username Username of the user changing password
     * @param request Password change request containing current and new passwords
     * @return Success message
     * @throws UserNotFoundException if user not found
     * @throws InvalidUserOperationException if validation fails
     */
    @Transactional
    public String changePassword(String username, PasswordChangeRequestDTO request) {
        log.info("Password change requested for user: {}", username);

        // Find user
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new UserNotFoundException("User not found: " + username));

        // Verify old password using passwordEncoder.matches()
        if (!passwordEncoder.matches(request.getCurrentPassword(), user.getPassword())) {
            log.warn("Invalid current password provided for user: {}", username);
            throw new InvalidUserOperationException("Current password is incorrect");
        }

        // Validate new password requirements (min 6 chars)
        validatePasswordRequirements(request.getNewPassword());

        // Ensure new password != old password
        if (passwordEncoder.matches(request.getNewPassword(), user.getPassword())) {
            log.warn("New password is same as current password for user: {}", username);
            throw new InvalidUserOperationException("New password must be different from current password");
        }

        // Ensure newPassword == confirmPassword
        if (!request.getNewPassword().equals(request.getConfirmPassword())) {
            log.warn("New password and confirmation do not match for user: {}", username);
            throw new InvalidUserOperationException("New password and confirmation password do not match");
        }

        // Encode with passwordEncoder.encode()
        user.setPassword(passwordEncoder.encode(request.getNewPassword()));

        // Set mustChangePassword = false
        user.setMustChangePassword(false);

        userRepository.save(user);

        log.info("Password changed successfully for user: {}", username);
        return "Password changed successfully";
    }

    /**
     * Reset user password to a temporary password (admin operation)
     *
     * SECURITY WARNING: This method generates and returns a plaintext temporary password.
     * This is the ONLY operation where plaintext passwords are returned.
     * The temporary password must be:
     * - Communicated securely to the user
     * - Changed immediately upon first login
     * - Never logged or stored in plaintext
     *
     * @param adminUsername Username of the administrator performing the reset
     * @param userId ID of the user whose password is being reset
     * @return Plaintext temporary password (ONLY time this is allowed)
     * @throws UserNotFoundException if user not found
     * @throws InsufficientPermissionException if admin lacks permission
     */
    @Transactional
    public String resetUserPassword(String adminUsername, Long userId) {
        log.info("Admin {} requesting password reset for user ID: {}", adminUsername, userId);

        // Find target user
        User targetUser = userRepository.findById(userId)
                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + userId));

        // Verify admin permissions using verifyAdminPermission
        verifyAdminPermission(adminUsername, targetUser);

        // Generate 8-character temporary password
        String temporaryPassword = generateTemporaryPassword();

        // Encode password before saving
        targetUser.setPassword(passwordEncoder.encode(temporaryPassword));

        // Set mustChangePassword = true
        targetUser.setMustChangePassword(true);

        userRepository.save(targetUser);

        // Log reset action with admin username (NOT the password)
        log.info("Password reset successfully by admin {} for user: {}",
                adminUsername, targetUser.getUsername());

        // Return plaintext temporary password (only time this is allowed)
        return temporaryPassword;
    }

    /**
     * Validate password meets minimum requirements
     *
     * Current requirements:
     * - Minimum 6 characters
     *
     * @param password Password to validate
     * @throws InvalidUserOperationException if password does not meet requirements
     */
    private void validatePasswordRequirements(String password) {
        // Check minimum 6 characters
        if (password == null || password.length() < 6) {
            throw new InvalidUserOperationException(
                    "Password must be at least 6 characters long");
        }
    }

    /**
     * Generate a secure temporary password
     *
     * SECURITY NOTE: This password is generated using SecureRandom for cryptographic strength.
     * The password includes uppercase letters, lowercase letters, and digits for complexity.
     *
     * @return 8-character temporary password in plaintext
     */
    private String generateTemporaryPassword() {
        // Character sets for password generation
        String uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        String lowercase = "abcdefghijklmnopqrstuvwxyz";
        String digits = "0123456789";
        String allCharacters = uppercase + lowercase + digits;

        // Use SecureRandom for cryptographically strong random generation
        SecureRandom random = new SecureRandom();
        StringBuilder password = new StringBuilder(8);

        // Ensure at least one of each character type
        password.append(uppercase.charAt(random.nextInt(uppercase.length())));
        password.append(lowercase.charAt(random.nextInt(lowercase.length())));
        password.append(digits.charAt(random.nextInt(digits.length())));

        // Fill remaining 5 characters randomly
        for (int i = 3; i < 8; i++) {
            password.append(allCharacters.charAt(random.nextInt(allCharacters.length())));
        }

        // Shuffle the password to randomize character positions
        char[] passwordArray = password.toString().toCharArray();
        for (int i = passwordArray.length - 1; i > 0; i--) {
            int j = random.nextInt(i + 1);
            char temp = passwordArray[i];
            passwordArray[i] = passwordArray[j];
            passwordArray[j] = temp;
        }

        return new String(passwordArray);
    }

    /**
     * Generate a unique customer ID for approval workflow
     * Format: CUST + 4-digit random number
     *
     * @return Unique customer ID
     */
    private String generateCustomerIdForApproval() {
        String customerId;
        do {
            int randomNum = new Random().nextInt(9000) + 1000;
            customerId = "CUST" + randomNum;
        } while (customerRepository.existsByCustomerId(customerId));

        log.debug("Generated unique customer ID: {}", customerId);
        return customerId;
    }

    // ============================================================================
    // EXISTING USER MANAGEMENT METHODS (continued)
    // ============================================================================

    /**
     * Update user role (admin operation)
     * Enforces permission hierarchy: SUPER_ADMIN > ADMIN > others
     *
     * @param adminUsername Username of the admin performing the operation
     * @param userId User ID to update
     * @param newRoleStr New role as string
     * @return Updated user details
     * @throws UserNotFoundException if user or admin not found
     * @throws InsufficientPermissionException if admin lacks permission
     * @throws InvalidUserOperationException if invalid role or transition
     */
    @Transactional
    public UserResponseDTO updateUserRole(String adminUsername, Long userId, String newRoleStr) {
        log.info("Admin {} updating role for user ID: {}", adminUsername, userId);

        User targetUser = userRepository.findById(userId)
                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + userId));

        // Verify admin has permission to modify this user
        verifyAdminPermission(adminUsername, targetUser);

        // Parse and validate new role
        User.Role newRole;
        try {
            newRole = User.Role.valueOf(newRoleStr.toUpperCase());
        } catch (IllegalArgumentException e) {
            log.error("Invalid role: {}", newRoleStr);
            throw new InvalidUserOperationException("Invalid role: " + newRoleStr);
        }

        User.Role oldRole = targetUser.getRole();

        // Update role
        targetUser.setRole(newRole);

        // Validate and handle branch requirements for new role
        if (newRole == User.Role.BRANCH_MANAGER ||
                newRole == User.Role.LOAN_OFFICER ||
                newRole == User.Role.CARD_OFFICER ||
                newRole == User.Role.EMPLOYEE) {
            if (targetUser.getBranch() == null) {
                log.warn("Role {} requires branch assignment but user {} has no branch",
                        newRole, targetUser.getUsername());
                throw new InvalidUserOperationException(
                        newRole + " requires branch assignment. Please assign a branch first.");
            }
        } else if (newRole == User.Role.ADMIN ||
                newRole == User.Role.SUPER_ADMIN ||
                newRole == User.Role.CUSTOMER) {
            // These roles should not have branch assignment
            if (targetUser.getBranch() != null) {
                log.info("Removing branch assignment for role {}", newRole);
                targetUser.setBranch(null);
            }
        }

        targetUser = userRepository.save(targetUser);

        log.info("Admin {} updated user {} role from {} to {}",
                adminUsername, targetUser.getUsername(), oldRole, newRole);

        return mapToResponseDTO(targetUser);
    }

    /**
     * Update user's branch assignment (admin operation)
     *
     * @param adminUsername Username of the admin performing the operation
     * @param userId User ID to update
     * @param newBranchId New branch ID
     * @return Updated user details
     * @throws UserNotFoundException if user not found
     * @throws ResourceNotFoundException if branch not found
     * @throws InsufficientPermissionException if admin lacks permission
     * @throws InvalidUserOperationException if role doesn't require branch
     */
    @Transactional
    public UserResponseDTO updateBranchId(String adminUsername, Long userId, Long newBranchId) {
        log.info("Admin {} updating branch for user ID: {} to branch ID: {}",
                adminUsername, userId, newBranchId);

        User targetUser = userRepository.findById(userId)
                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + userId));

        // Verify admin has permission to modify this user
        verifyAdminPermission(adminUsername, targetUser);

        // Find and validate new branch
        Branch newBranch = branchRepository.findById(newBranchId)
                .orElseThrow(() -> new ResourceNotFoundException("Branch not found with ID: " + newBranchId));

        if (newBranch.getStatus() != Branch.BranchStatus.ACTIVE) {
            log.warn("Attempted to assign user to inactive branch: {}", newBranch.getBranchCode());
            throw new InvalidUserOperationException(
                    "Cannot assign user to inactive branch: " + newBranch.getBranchCode());
        }

        // Validate role requires branch assignment
        User.Role role = targetUser.getRole();
        if (role == User.Role.ADMIN || role == User.Role.SUPER_ADMIN || role == User.Role.CUSTOMER) {
            log.warn("Attempted to assign branch to role {} which should not have branch", role);
            throw new InvalidUserOperationException(
                    role + " should not be assigned to a branch");
        }

        String oldBranchCode = targetUser.getBranch() != null ?
                targetUser.getBranch().getBranchCode() : "N/A";

        targetUser.setBranch(newBranch);
        targetUser = userRepository.save(targetUser);

        log.info("Admin {} updated user {} branch from {} to {}",
                adminUsername, targetUser.getUsername(), oldBranchCode, newBranch.getBranchCode());

        return mapToResponseDTO(targetUser);
    }

    /**
     * Update user email (admin operation)
     *
     * @param adminUsername Username of the admin performing the operation
     * @param userId User ID to update
     * @param newEmail New email address
     * @return Updated user details
     * @throws UserNotFoundException if user not found
     * @throws UserAlreadyExistsException if email already exists
     * @throws InsufficientPermissionException if admin lacks permission
     */
    @Transactional
    public UserResponseDTO updateUserEmail(String adminUsername, Long userId, String newEmail) {
        log.info("Admin {} updating email for user ID: {}", adminUsername, userId);

        User targetUser = userRepository.findById(userId)
                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + userId));

        // Verify admin has permission to modify this user
        verifyAdminPermission(adminUsername, targetUser);

        // Validate email format and uniqueness
        if (newEmail == null || newEmail.trim().isEmpty()) {
            throw new InvalidUserOperationException("Email cannot be empty");
        }

        if (!newEmail.matches("^[A-Za-z0-9+_.-]+@(.+)$")) {
            throw new InvalidUserOperationException("Invalid email format");
        }

        if (!targetUser.getEmail().equals(newEmail) && userRepository.existsByEmail(newEmail)) {
            log.warn("Email already exists: {}", newEmail);
            throw new UserAlreadyExistsException("Email already exists: " + newEmail);
        }

        String oldEmail = targetUser.getEmail();

        // Store final values for use in lambda
        final String finalNewEmail = newEmail;
        final Long finalTargetUserId = targetUser.getId();

        targetUser.setEmail(newEmail);
        targetUser = userRepository.save(targetUser);

        // Update Customer email if this is a CUSTOMER user
        if (targetUser.getRole() == User.Role.CUSTOMER) {
            customerRepository.findAll().stream()
                    .filter(c -> c.getUser() != null && c.getUser().getId().equals(finalTargetUserId))
                    .findFirst()
                    .ifPresent(customer -> {
                        customer.setEmail(finalNewEmail);
                        customerRepository.save(customer);
                        log.info("Updated Customer email to match new User email");
                    });
        }

        log.info("Admin {} updated user {} email from {} to {}",
                adminUsername, targetUser.getUsername(), oldEmail, newEmail);

        return mapToResponseDTO(targetUser);
    }

    /**
     * Update user phone number (admin operation)
     * Note: Requires adding phone field to User entity
     *
     * @param adminUsername Username of the admin performing the operation
     * @param userId User ID to update
     * @param newPhone New phone number
     * @return Updated user details
     * @throws UserNotFoundException if user not found
     * @throws InsufficientPermissionException if admin lacks permission
     * @throws InvalidUserOperationException if invalid phone format
     */
    @Transactional
    public UserResponseDTO updateUserPhone(String adminUsername, Long userId, String newPhone) {
        log.info("Admin {} updating phone for user ID: {}", adminUsername, userId);

        User targetUser = userRepository.findById(userId)
                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + userId));

        // Verify admin has permission to modify this user
        verifyAdminPermission(adminUsername, targetUser);

        // Validate phone format
        if (newPhone == null || newPhone.trim().isEmpty()) {
            throw new InvalidUserOperationException("Phone number cannot be empty");
        }

        if (!newPhone.matches("^\\+?[1-9]\\d{1,14}$")) {
            throw new InvalidUserOperationException("Invalid phone number format");
        }

        // Note: This assumes User entity has a phone field
        // If not, this method should be removed or User entity should be extended
        log.warn("Phone update requested but User entity may not have phone field");
        log.info("Admin {} requested phone update for user {} to {}",
                adminUsername, targetUser.getUsername(), newPhone);

        // Placeholder - actual implementation requires User entity modification
        throw new InvalidUserOperationException(
                "Phone number management not yet implemented for User entity");
    }

    /**
     * Promote user to new role with branch assignment (admin operation)
     * Combines role and branch update in single atomic transaction
     *
     * @param adminUsername Username of the admin performing the operation
     * @param userId User ID to promote
     * @param newRoleStr New role as string
     * @param newBranchId New branch ID (can be null for non-branch roles)
     * @return Updated user details
     * @throws UserNotFoundException if user not found
     * @throws ResourceNotFoundException if branch not found
     * @throws InsufficientPermissionException if admin lacks permission
     * @throws InvalidUserOperationException if invalid promotion
     */
    @Transactional
    public UserResponseDTO promoteUser(String adminUsername, Long userId, String newRoleStr, Long newBranchId) {
        log.info("Admin {} promoting user ID: {} to role {} with branch ID: {}",
                adminUsername, userId, newRoleStr, newBranchId);

        User targetUser = userRepository.findById(userId)
                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + userId));

        // Verify admin has permission to modify this user
        verifyAdminPermission(adminUsername, targetUser);

        // Parse and validate new role
        User.Role newRole;
        try {
            newRole = User.Role.valueOf(newRoleStr.toUpperCase());
        } catch (IllegalArgumentException e) {
            log.error("Invalid role: {}", newRoleStr);
            throw new InvalidUserOperationException("Invalid role: " + newRoleStr);
        }

        User.Role oldRole = targetUser.getRole();
        String oldBranchCode = targetUser.getBranch() != null ?
                targetUser.getBranch().getBranchCode() : "N/A";

        // Handle branch assignment based on new role
        if (newRole == User.Role.BRANCH_MANAGER ||
                newRole == User.Role.LOAN_OFFICER ||
                newRole == User.Role.CARD_OFFICER ||
                newRole == User.Role.EMPLOYEE) {

            if (newBranchId == null) {
                throw new InvalidUserOperationException(
                        newRole + " requires branch assignment");
            }

            Branch newBranch = branchRepository.findById(newBranchId)
                    .orElseThrow(() -> new ResourceNotFoundException(
                            "Branch not found with ID: " + newBranchId));

            if (newBranch.getStatus() != Branch.BranchStatus.ACTIVE) {
                throw new InvalidUserOperationException(
                        "Cannot assign user to inactive branch: " + newBranch.getBranchCode());
            }

            targetUser.setBranch(newBranch);

        } else if (newRole == User.Role.ADMIN ||
                newRole == User.Role.SUPER_ADMIN ||
                newRole == User.Role.CUSTOMER) {
            // These roles should not have branch
            targetUser.setBranch(null);
        }

        // Update role
        targetUser.setRole(newRole);

        // Ensure user is active after promotion
        if (targetUser.getUserStatus() != User.UserStatus.ACTIVE) {
            targetUser.setUserStatus(User.UserStatus.ACTIVE);
            targetUser.setIsActive(true);
        }

        targetUser = userRepository.save(targetUser);

        log.info("Admin {} promoted user {} from {} ({}) to {} ({})",
                adminUsername, targetUser.getUsername(), oldRole, oldBranchCode,
                newRole, targetUser.getBranch() != null ? targetUser.getBranch().getBranchCode() : "N/A");

        return mapToResponseDTO(targetUser);
    }

    /**
     * Deactivate a user account (admin operation)
     * Prevents deactivation of SUPER_ADMIN and last active ADMIN
     *
     * @param adminUsername Username of the admin performing the operation
     * @param userId User ID to deactivate
     * @throws UserNotFoundException if user not found
     * @throws InsufficientPermissionException if admin lacks permission
     * @throws InvalidUserOperationException if user cannot be deactivated
     */
    @Transactional
    public void deactivateUser(String adminUsername, Long userId) {
        log.info("Admin {} deactivating user ID: {}", adminUsername, userId);

        User admin = userRepository.findByUsername(adminUsername)
                .orElseThrow(() -> new UserNotFoundException("Admin user not found: " + adminUsername));

        User targetUser = userRepository.findById(userId)
                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + userId));

        // Prevent self-deactivation
        if (admin.getId().equals(targetUser.getId())) {
            log.warn("Admin {} attempted to deactivate themselves", adminUsername);
            throw new InvalidUserOperationException("Cannot deactivate your own account");
        }

        // Verify admin has permission to modify this user
        verifyAdminPermission(adminUsername, targetUser);

        // Validate user can be deactivated
        validateUserCanBeDeactivated(targetUser);

        targetUser.setUserStatus(User.UserStatus.INACTIVE);
        targetUser.setIsActive(false);

        userRepository.save(targetUser);

        // Deactivate Customer if this is a CUSTOMER user (after saving user)
        if (targetUser.getRole() == User.Role.CUSTOMER) {
            final Long finalTargetUserId = targetUser.getId();
            final String finalTargetUsername = targetUser.getUsername();

            customerRepository.findAll().stream()
                    .filter(c -> c.getUser() != null && c.getUser().getId().equals(finalTargetUserId))
                    .findFirst()
                    .ifPresent(customer -> {
                        customer.setStatus(Customer.Status.INACTIVE);
                        customerRepository.save(customer);
                        log.info("Deactivated Customer entity for user: {}", finalTargetUsername);
                    });
        }

        log.info("Admin {} deactivated user {}", adminUsername, targetUser.getUsername());
    }

    /**
     * Reactivate a deactivated user account (admin operation)
     *
     * @param adminUsername Username of the admin performing the operation
     * @param userId User ID to reactivate
     * @return Updated user details
     * @throws UserNotFoundException if user not found
     * @throws InsufficientPermissionException if admin lacks permission
     */
    @Transactional
    public UserResponseDTO reactivateUser(String adminUsername, Long userId) {
        log.info("Admin {} reactivating user ID: {}", adminUsername, userId);

        User targetUser = userRepository.findById(userId)
                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + userId));

        // Verify admin has permission to modify this user
        verifyAdminPermission(adminUsername, targetUser);

        targetUser.setUserStatus(User.UserStatus.ACTIVE);
        targetUser.setIsActive(true);

        targetUser = userRepository.save(targetUser);

        // Reactivate Customer if this is a CUSTOMER user (after saving user)
        if (targetUser.getRole() == User.Role.CUSTOMER) {
            final Long finalTargetUserId = targetUser.getId();
            final String finalTargetUsername = targetUser.getUsername();

            customerRepository.findAll().stream()
                    .filter(c -> c.getUser() != null && c.getUser().getId().equals(finalTargetUserId))
                    .findFirst()
                    .ifPresent(customer -> {
                        customer.setStatus(Customer.Status.ACTIVE);
                        customerRepository.save(customer);
                        log.info("Reactivated Customer entity for user: {}", finalTargetUsername);
                    });
        }

        log.info("Admin {} reactivated user {}", adminUsername, targetUser.getUsername());

        return mapToResponseDTO(targetUser);
    }

    /**
     * Get all users in a specific branch
     *
     * @param branchId Branch ID
     * @return List of users in the branch
     * @throws ResourceNotFoundException if branch not found
     */
    @Transactional(readOnly = true)
    public List<UserResponseDTO> getUsersByBranch(Long branchId) {
        log.info("Fetching users for branch ID: {}", branchId);

        // Verify branch exists
        branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Branch not found with ID: " + branchId));

        List<User> users = userRepository.findByBranchId(branchId);

        log.info("Retrieved {} users for branch ID: {}", users.size(), branchId);

        return users.stream()
                .map(this::mapToResponseDTO)
                .collect(Collectors.toList());
    }

    /**
     * Get all users with a specific status
     *
     * @param status User status (PENDING, ACTIVE, INACTIVE)
     * @return List of users with the specified status
     * @throws InvalidUserOperationException if invalid status
     */
    @Transactional(readOnly = true)
    public List<UserResponseDTO> getUsersByStatus(String status) {
        log.info("Fetching users by status: {}", status);

        User.UserStatus userStatus;
        try {
            userStatus = User.UserStatus.valueOf(status.toUpperCase());
        } catch (IllegalArgumentException e) {
            log.error("Invalid user status: {}", status);
            throw new InvalidUserOperationException("Invalid user status: " + status);
        }

        List<User> users = userRepository.findByUserStatus(userStatus);

        log.info("Retrieved {} users with status {}", users.size(), status);

        return users.stream()
                .map(this::mapToResponseDTO)
                .collect(Collectors.toList());
    }

    // ============================================================================
    // PRIVATE HELPER METHODS
    // ============================================================================

    /**
     * Map User entity to UserResponseDTO
     *
     * @param user User entity
     * @return UserResponseDTO
     */
    private UserResponseDTO mapToResponseDTO(User user) {
        UserResponseDTO dto = new UserResponseDTO();
        dto.setId(user.getId());
        dto.setUsername(user.getUsername());
        dto.setEmail(user.getEmail());
        dto.setRole(user.getRole().name());
        dto.setUserStatus(user.getUserStatus() != null ? user.getUserStatus().name() : null);
        dto.setIsActive(user.getIsActive());
        dto.setMustChangePassword(user.getMustChangePassword());

        if (user.getBranch() != null) {
            dto.setBranchId(user.getBranch().getId());
            dto.setBranchCode(user.getBranch().getBranchCode());
            dto.setBranchName(user.getBranch().getBranchName());
        }

        dto.setApprovalReason(user.getApprovalReason());
        dto.setApprovedBy(user.getApprovedBy());
        dto.setApprovedDate(user.getApprovedDate());
        dto.setCreatedDate(user.getCreatedDate());
        dto.setLastModified(user.getLastModified());

        return dto;
    }

    /**
     * Map User entity to PendingUserResponseDTO
     *
     * @param user User entity
     * @return PendingUserResponseDTO
     */
    private PendingUserResponseDTO mapToPendingUserDTO(User user) {
        PendingUserResponseDTO dto = new PendingUserResponseDTO();
        dto.setId(user.getId());
        dto.setUsername(user.getUsername());
        dto.setEmail(user.getEmail());
        dto.setRole(user.getRole().name());
        dto.setUserStatus(user.getUserStatus() != null ? user.getUserStatus().name() : null);
        dto.setBranchCode(user.getBranch() != null ? user.getBranch().getBranchCode() : null);
        dto.setBranchName(user.getBranch() != null ? user.getBranch().getBranchName() : null);
        dto.setCreatedDate(user.getCreatedDate());
        dto.setApprovalReason(user.getApprovalReason());

        return dto;
    }

    /**
     * Verify admin has permission to modify target user
     * Implements permission hierarchy: SUPER_ADMIN > ADMIN > others
     *
     * @param adminUsername Admin username
     * @param targetUser Target user to be modified
     * @throws UserNotFoundException if admin not found
     * @throws InsufficientPermissionException if insufficient permission
     */
    private void verifyAdminPermission(String adminUsername, User targetUser) {
        User admin = userRepository.findByUsername(adminUsername)
                .orElseThrow(() -> new UserNotFoundException("Admin user not found: " + adminUsername));

        // SUPER_ADMIN can modify anyone
        if (admin.getRole() == User.Role.SUPER_ADMIN) {
            log.debug("SUPER_ADMIN {} has permission to modify user {}",
                    adminUsername, targetUser.getUsername());
            return;
        }

        // ADMIN cannot modify SUPER_ADMIN or other ADMINs
        if (admin.getRole() == User.Role.ADMIN) {
            if (targetUser.getRole() == User.Role.SUPER_ADMIN) {
                log.warn("ADMIN {} attempted to modify SUPER_ADMIN user {}",
                        adminUsername, targetUser.getUsername());
                throw new InsufficientPermissionException(
                        "Admin cannot modify Super Admin accounts");
            }

            if (targetUser.getRole() == User.Role.ADMIN) {
                log.warn("ADMIN {} attempted to modify another ADMIN user {}",
                        adminUsername, targetUser.getUsername());
                throw new InsufficientPermissionException(
                        "Admin cannot modify other Admin accounts");
            }

            log.debug("ADMIN {} has permission to modify user {}",
                    adminUsername, targetUser.getUsername());
            return;
        }

        // All other roles cannot perform admin operations
        log.warn("User {} with role {} attempted admin operation on user {}",
                adminUsername, admin.getRole(), targetUser.getUsername());
        throw new InsufficientPermissionException(
                "Insufficient permissions to perform this operation");
    }

    /**
     * Validate user can be deactivated
     * Prevents deactivation of SUPER_ADMIN and last active ADMIN
     *
     * @param user User to validate
     * @throws InvalidUserOperationException if user cannot be deactivated
     */
    private void validateUserCanBeDeactivated(User user) {
        // Prevent deactivation of SUPER_ADMIN
        if (user.getRole() == User.Role.SUPER_ADMIN) {
            log.warn("Attempted to deactivate SUPER_ADMIN user: {}", user.getUsername());
            throw new InvalidUserOperationException(
                    "Super Admin accounts cannot be deactivated");
        }

        // Prevent deactivation of last active ADMIN
        if (user.getRole() == User.Role.ADMIN) {
            long activeAdminCount = userRepository.findByRole(User.Role.ADMIN).stream()
                    .filter(u -> u.getUserStatus() == User.UserStatus.ACTIVE && u.getIsActive())
                    .count();

            if (activeAdminCount <= 1) {
                log.warn("Attempted to deactivate the last active ADMIN user: {}", user.getUsername());
                throw new InvalidUserOperationException(
                        "Cannot deactivate the last active Admin account");
            }
        }
    }

    /**
     * Get user details by username
     *
     * This method supports the /api/users/me endpoint for retrieving
     * the current authenticated user's profile.
     *
     * @param username Username to look up
     * @return UserResponseDTO with user details
     * @throws UserNotFoundException if user not found
     */
    @Transactional(readOnly = true)
    public UserResponseDTO getUserByUsername(String username) {
        log.info("Fetching user by username: {}", username);

        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new UserNotFoundException("User not found with username: " + username));

        return mapToResponseDTO(user);
    }
}

















//=========================================================================
//                         OLD VERSION
//=========================================================================


//
//
//package com.izak.demoBankManagement.service;
//
//import com.izak.demoBankManagement.dto.*;
//import com.izak.demoBankManagement.entity.Branch;
//import com.izak.demoBankManagement.entity.Customer;
//import com.izak.demoBankManagement.entity.User;
//import com.izak.demoBankManagement.exception.*;
//import com.izak.demoBankManagement.repository.BranchRepository;
//import com.izak.demoBankManagement.repository.CustomerRepository;
//import com.izak.demoBankManagement.repository.UserRepository;
//import lombok.RequiredArgsConstructor;
//import lombok.extern.slf4j.Slf4j;
//import org.springframework.security.crypto.password.PasswordEncoder;
//import org.springframework.stereotype.Service;
//import org.springframework.transaction.annotation.Transactional;
//
//import java.security.SecureRandom;
//import java.time.LocalDateTime;
//import java.util.List;
//import java.util.stream.Collectors;
//
///**
// * Service for managing user accounts and approval workflows.
// * Handles user registration, approval/rejection, password management, and user queries.
// */
//@Service
//@RequiredArgsConstructor
//@Slf4j
//public class UserManagementService {
//
//    private final UserRepository userRepository;
//    private final BranchRepository branchRepository;
//    private final CustomerRepository customerRepository;
//    private final PasswordEncoder passwordEncoder;
//    private final BranchAuthorizationService branchAuthorizationService;
//
//    // ============================================================================
//    // EXISTING METHODS (from original UserManagementService)
//    // ============================================================================
//
//    /**
//     * Register a new user with PENDING status
//     * Only CUSTOMER and EMPLOYEE roles are allowed for self-registration
//     * Higher roles (ADMIN, SUPER_ADMIN) must be assigned by administrators
//     *
//     * @param request User registration details
//     * @return UserResponseDTO with created user details
//     * @throws UserAlreadyExistsException if username or email already exists
//     * @throws InvalidUserOperationException if invalid role or missing branch for EMPLOYEE
//     * @throws ResourceNotFoundException if branch not found
//     */
//    @Transactional
//    public UserResponseDTO registerUser(UserRegistrationRequestDTO request) {
//        log.info("Registering new user: {}", request.getUsername());
//
//        // Validate username uniqueness
//        if (userRepository.existsByUsername(request.getUsername())) {
//            log.warn("Username already exists: {}", request.getUsername());
//            throw new UserAlreadyExistsException("Username already exists: " + request.getUsername());
//        }
//
//        // Validate email uniqueness
//        if (userRepository.existsByEmail(request.getEmail())) {
//            log.warn("Email already exists: {}", request.getEmail());
//            throw new UserAlreadyExistsException("Email already exists: " + request.getEmail());
//        }
//
//        // Validate role restriction for self-registration
//        User.Role role;
//        try {
//            role = User.Role.valueOf(request.getRole().toUpperCase());
//        } catch (IllegalArgumentException e) {
//            log.error("Invalid role: {}", request.getRole());
//            throw new InvalidUserOperationException("Invalid role: " + request.getRole());
//        }
//
//        if (role != User.Role.CUSTOMER && role != User.Role.EMPLOYEE) {
//            log.warn("Attempted self-registration with restricted role: {}", role);
//            throw new InvalidUserOperationException(
//                    "Self-registration is only allowed for CUSTOMER and EMPLOYEE roles. " +
//                            "Higher roles must be assigned by administrators.");
//        }
//
//        // Create new user
//        User user = new User();
//        user.setUsername(request.getUsername());
//        user.setPassword(passwordEncoder.encode(request.getPassword()));
//        user.setEmail(request.getEmail());
//        user.setRole(role);
//        user.setUserStatus(User.UserStatus.PENDING); // Default to PENDING for approval workflow
//        user.setIsActive(false); // Inactive until approved
//        user.setMustChangePassword(false);
//
//        // Handle branch assignment for EMPLOYEE role
//        if (role == User.Role.EMPLOYEE) {
//            if (request.getBranchCode() != null && !request.getBranchCode().trim().isEmpty()) {
//                Branch branch = branchRepository.findByBranchCode(request.getBranchCode())
//                        .orElseThrow(() -> new ResourceNotFoundException(
//                                "Branch not found with code: " + request.getBranchCode()));
//
//                if (branch.getStatus() != Branch.BranchStatus.ACTIVE) {
//                    log.warn("Attempted to assign user to inactive branch: {}", request.getBranchCode());
//                    throw new InvalidUserOperationException(
//                            "Cannot assign user to inactive branch: " + request.getBranchCode());
//                }
//
//                user.setBranch(branch);
//                log.info("Assigned user {} to branch {}", request.getUsername(), branch.getBranchCode());
//            } else {
//                log.info("EMPLOYEE registration without branch assignment - will require admin assignment");
//            }
//        }
//
//        user = userRepository.save(user);
//
//        log.info("User registered successfully: {} with status PENDING", user.getUsername());
//
//        return mapToResponseDTO(user);
//    }
//
//    /**
//     * Get all users with PENDING status awaiting approval
//     *
//     * @return List of pending users
//     */
//    @Transactional(readOnly = true)
//    public List<PendingUserResponseDTO> getPendingApprovals() {
//        log.info("Fetching all pending user approvals");
//
//        List<User> pendingUsers = userRepository.findByUserStatus(User.UserStatus.PENDING);
//
//        log.info("Found {} pending user approvals", pendingUsers.size());
//
//        return pendingUsers.stream()
//                .map(this::mapToPendingUserDTO)
//                .collect(Collectors.toList());
//    }
//
//    /**
//     * Approve a pending user and activate their account
//     * Can optionally override role and assign branch during approval
//     *
//     * @param adminUsername Username of the approving administrator
//     * @param request Approval request with optional role/branch assignment
//     * @return UserResponseDTO with updated user details
//     * @throws UserNotFoundException if user not found
//     * @throws InvalidUserOperationException if user not in PENDING status or invalid role/branch
//     * @throws ResourceNotFoundException if branch not found
//     */
//    @Transactional
//    public UserResponseDTO approveUser(String adminUsername, UserApprovalRequestDTO request) {
//        log.info("Admin {} approving user ID: {}", adminUsername, request.getUserId());
//
//        User user = userRepository.findById(request.getUserId())
//                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + request.getUserId()));
//
//        if (user.getUserStatus() != User.UserStatus.PENDING) {
//            log.warn("Attempted to approve user {} with status: {}", user.getUsername(), user.getUserStatus());
//            throw new InvalidUserOperationException(
//                    "User is not in PENDING status. Current status: " + user.getUserStatus());
//        }
//
//        // Override role if provided
//        if (request.getAssignedRole() != null && !request.getAssignedRole().trim().isEmpty()) {
//            try {
//                User.Role newRole = User.Role.valueOf(request.getAssignedRole().toUpperCase());
//                user.setRole(newRole);
//                log.info("Role updated from {} to {} during approval", user.getRole(), newRole);
//            } catch (IllegalArgumentException e) {
//                log.error("Invalid assigned role: {}", request.getAssignedRole());
//                throw new InvalidUserOperationException("Invalid role: " + request.getAssignedRole());
//            }
//        }
//
//        // Assign or update branch if provided
//        if (request.getBranchCode() != null && !request.getBranchCode().trim().isEmpty()) {
//            Branch branch = branchRepository.findByBranchCode(request.getBranchCode())
//                    .orElseThrow(() -> new ResourceNotFoundException(
//                            "Branch not found with code: " + request.getBranchCode()));
//
//            if (branch.getStatus() != Branch.BranchStatus.ACTIVE) {
//                log.warn("Attempted to assign user to inactive branch: {}", request.getBranchCode());
//                throw new InvalidUserOperationException(
//                        "Cannot assign user to inactive branch: " + request.getBranchCode());
//            }
//
//            user.setBranch(branch);
//            log.info("Branch assigned/updated to {} during approval", branch.getBranchCode());
//        }
//
//        // Validate branch assignment for certain roles
//        if ((user.getRole() == User.Role.BRANCH_MANAGER ||
//                user.getRole() == User.Role.LOAN_OFFICER ||
//                user.getRole() == User.Role.CARD_OFFICER) && user.getBranch() == null) {
//            log.warn("Attempted to approve {} without branch assignment", user.getRole());
//            throw new InvalidUserOperationException(
//                    user.getRole() + " must be assigned to a branch");
//        }
//
//        // Update approval fields
//        user.setUserStatus(User.UserStatus.ACTIVE);
//        user.setIsActive(true);
//        user.setApprovedBy(adminUsername);
//        user.setApprovedDate(LocalDateTime.now());
//        user.setApprovalReason(request.getReason());
//
//        user = userRepository.save(user);
//
//        log.info("User {} approved successfully by {}", user.getUsername(), adminUsername);
//
//        return mapToResponseDTO(user);
//    }
//
//    /**
//     * Reject a pending user registration
//     *
//     * @param adminUsername Username of the rejecting administrator
//     * @param userId User ID to reject
//     * @param reason Reason for rejection
//     * @throws UserNotFoundException if user not found
//     * @throws InvalidUserOperationException if user not in PENDING status
//     */
//    @Transactional
//    public void rejectUser(String adminUsername, Long userId, String reason) {
//        log.info("Admin {} rejecting user ID: {}", adminUsername, userId);
//
//        User user = userRepository.findById(userId)
//                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + userId));
//
//        if (user.getUserStatus() != User.UserStatus.PENDING) {
//            log.warn("Attempted to reject user {} with status: {}", user.getUsername(), user.getUserStatus());
//            throw new InvalidUserOperationException(
//                    "User is not in PENDING status. Current status: " + user.getUserStatus());
//        }
//
//        user.setUserStatus(User.UserStatus.INACTIVE);
//        user.setIsActive(false);
//        user.setApprovedBy(adminUsername);
//        user.setApprovedDate(LocalDateTime.now());
//        user.setApprovalReason(reason != null ? reason : "Registration rejected");
//
//        userRepository.save(user);
//
//        log.info("User {} rejected successfully by {}", user.getUsername(), adminUsername);
//    }
//
//    /**
//     * Get user details by ID
//     *
//     * @param userId User ID
//     * @return UserResponseDTO with user details
//     * @throws UserNotFoundException if user not found
//     */
//    @Transactional(readOnly = true)
//    public UserResponseDTO getUserById(Long userId) {
//        log.info("Fetching user by ID: {}", userId);
//
//        User user = userRepository.findById(userId)
//                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + userId));
//
//        return mapToResponseDTO(user);
//    }
//
//    /**
//     * Get all users in the system
//     *
//     * @return List of all users
//     */
//    @Transactional(readOnly = true)
//    public List<UserResponseDTO> getAllUsers() {
//        log.info("Fetching all users");
//
//        List<User> users = userRepository.findAll();
//
//        log.info("Retrieved {} users", users.size());
//
//        return users.stream()
//                .map(this::mapToResponseDTO)
//                .collect(Collectors.toList());
//    }
//
//    /**
//     * Get all users with a specific role
//     *
//     * @param role Role name (e.g., "ADMIN", "CUSTOMER")
//     * @return List of users with the specified role
//     * @throws InvalidUserOperationException if invalid role provided
//     */
//    @Transactional(readOnly = true)
//    public List<UserResponseDTO> getUsersByRole(String role) {
//        log.info("Fetching users by role: {}", role);
//
//        User.Role userRole;
//        try {
//            userRole = User.Role.valueOf(role.toUpperCase());
//        } catch (IllegalArgumentException e) {
//            log.error("Invalid role: {}", role);
//            throw new InvalidUserOperationException("Invalid role: " + role);
//        }
//
//        List<User> users = userRepository.findByRole(userRole);
//
//        log.info("Retrieved {} users with role {}", users.size(), role);
//
//        return users.stream()
//                .map(this::mapToResponseDTO)
//                .collect(Collectors.toList());
//    }
//
//    /**
//     * Update user details (admin operation)
//     *
//     * @param userId User ID to update
//     * @param request Update request with new values
//     * @return Updated user details
//     * @throws UserNotFoundException if user not found
//     * @throws UserAlreadyExistsException if email already exists for another user
//     * @throws InvalidUserOperationException if invalid role or branch
//     * @throws ResourceNotFoundException if branch not found
//     */
//    @Transactional
//    public UserResponseDTO updateUser(Long userId, UserUpdateRequestDTO request) {
//        log.info("Updating user ID: {}", userId);
//
//        User user = userRepository.findById(userId)
//                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + userId));
//
//        // Update email if provided
//        if (request.getEmail() != null && !request.getEmail().trim().isEmpty()) {
//            if (!user.getEmail().equals(request.getEmail()) &&
//                    userRepository.existsByEmail(request.getEmail())) {
//                log.warn("Email already exists: {}", request.getEmail());
//                throw new UserAlreadyExistsException("Email already exists: " + request.getEmail());
//            }
//            user.setEmail(request.getEmail());
//        }
//
//        // Update role if provided
//        if (request.getRole() != null && !request.getRole().trim().isEmpty()) {
//            try {
//                User.Role newRole = User.Role.valueOf(request.getRole().toUpperCase());
//                user.setRole(newRole);
//                log.info("Role updated to {}", newRole);
//            } catch (IllegalArgumentException e) {
//                log.error("Invalid role: {}", request.getRole());
//                throw new InvalidUserOperationException("Invalid role: " + request.getRole());
//            }
//        }
//
//        // Update user status if provided
//        if (request.getUserStatus() != null && !request.getUserStatus().trim().isEmpty()) {
//            try {
//                User.UserStatus newStatus = User.UserStatus.valueOf(request.getUserStatus().toUpperCase());
//                user.setUserStatus(newStatus);
//                log.info("User status updated to {}", newStatus);
//            } catch (IllegalArgumentException e) {
//                log.error("Invalid user status: {}", request.getUserStatus());
//                throw new InvalidUserOperationException("Invalid user status: " + request.getUserStatus());
//            }
//        }
//
//        // Update isActive if provided
//        if (request.getIsActive() != null) {
//            user.setIsActive(request.getIsActive());
//        }
//
//        // Update mustChangePassword if provided
//        if (request.getMustChangePassword() != null) {
//            user.setMustChangePassword(request.getMustChangePassword());
//        }
//
//        // Update branch if provided
//        if (request.getBranchCode() != null && !request.getBranchCode().trim().isEmpty()) {
//            Branch branch = branchRepository.findByBranchCode(request.getBranchCode())
//                    .orElseThrow(() -> new ResourceNotFoundException(
//                            "Branch not found with code: " + request.getBranchCode()));
//
//            if (branch.getStatus() != Branch.BranchStatus.ACTIVE) {
//                log.warn("Attempted to assign user to inactive branch: {}", request.getBranchCode());
//                throw new InvalidUserOperationException(
//                        "Cannot assign user to inactive branch: " + request.getBranchCode());
//            }
//
//            user.setBranch(branch);
//            log.info("Branch updated to {}", branch.getBranchCode());
//        }
//
//        user = userRepository.save(user);
//
//        log.info("User {} updated successfully", user.getUsername());
//
//        return mapToResponseDTO(user);
//    }
//
//    /**
//     * Change user password
//     *
//     * @param userId User ID
//     * @param request Password change request
//     * @throws UserNotFoundException if user not found
//     * @throws InvalidUserOperationException if current password incorrect or passwords don't match
//     */
//    @Transactional
//    public void changePassword(Long userId, PasswordChangeRequestDTO request) {
//        log.info("Changing password for user ID: {}", userId);
//
//        User user = userRepository.findById(userId)
//                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + userId));
//
//        // Validate current password
//        if (!passwordEncoder.matches(request.getCurrentPassword(), user.getPassword())) {
//            log.warn("Invalid current password for user {}", user.getUsername());
//            throw new InvalidUserOperationException("Current password is incorrect");
//        }
//
//        // Validate new password confirmation
//        if (!request.getNewPassword().equals(request.getConfirmPassword())) {
//            log.warn("New password and confirmation do not match for user {}", user.getUsername());
//            throw new InvalidUserOperationException("New password and confirmation do not match");
//        }
//
//        // Validate new password is different from current
//        if (passwordEncoder.matches(request.getNewPassword(), user.getPassword())) {
//            log.warn("New password is same as current password for user {}", user.getUsername());
//            throw new InvalidUserOperationException("New password must be different from current password");
//        }
//
//        // Update password
//        user.setPassword(passwordEncoder.encode(request.getNewPassword()));
//        user.setMustChangePassword(false);
//
//        userRepository.save(user);
//
//        log.info("Password changed successfully for user {}", user.getUsername());
//    }
//
//    // ============================================================================
//    // NEW PASSWORD MANAGEMENT METHODS
//    // ============================================================================
//
//    /**
//     * Change user password with enhanced security validations
//     *
//     * WARNING: This method handles sensitive password data. Ensure:
//     * - Current password is verified before allowing change
//     * - New password meets minimum requirements
//     * - New password differs from current password
//     * - Password is encoded before storage
//     * - No plaintext passwords are logged
//     *
//     * @param username Username of the user changing password
//     * @param request Password change request containing current and new passwords
//     * @return Success message
//     * @throws UserNotFoundException if user not found
//     * @throws InvalidUserOperationException if validation fails
//     */
//    @Transactional
//    public String changePassword(String username, PasswordChangeRequestDTO request) {
//        log.info("Password change requested for user: {}", username);
//
//        // Find user
//        User user = userRepository.findByUsername(username)
//                .orElseThrow(() -> new UserNotFoundException("User not found: " + username));
//
//        // Verify old password using passwordEncoder.matches()
//        if (!passwordEncoder.matches(request.getCurrentPassword(), user.getPassword())) {
//            log.warn("Invalid current password provided for user: {}", username);
//            throw new InvalidUserOperationException("Current password is incorrect");
//        }
//
//        // Validate new password requirements (min 6 chars)
//        validatePasswordRequirements(request.getNewPassword());
//
//        // Ensure new password != old password
//        if (passwordEncoder.matches(request.getNewPassword(), user.getPassword())) {
//            log.warn("New password is same as current password for user: {}", username);
//            throw new InvalidUserOperationException("New password must be different from current password");
//        }
//
//        // Ensure newPassword == confirmPassword
//        if (!request.getNewPassword().equals(request.getConfirmPassword())) {
//            log.warn("New password and confirmation do not match for user: {}", username);
//            throw new InvalidUserOperationException("New password and confirmation password do not match");
//        }
//
//        // Encode with passwordEncoder.encode()
//        user.setPassword(passwordEncoder.encode(request.getNewPassword()));
//
//        // Set mustChangePassword = false
//        user.setMustChangePassword(false);
//
//        userRepository.save(user);
//
//        log.info("Password changed successfully for user: {}", username);
//        return "Password changed successfully";
//    }
//
//    /**
//     * Reset user password to a temporary password (admin operation)
//     *
//     * SECURITY WARNING: This method generates and returns a plaintext temporary password.
//     * This is the ONLY operation where plaintext passwords are returned.
//     * The temporary password must be:
//     * - Communicated securely to the user
//     * - Changed immediately upon first login
//     * - Never logged or stored in plaintext
//     *
//     * @param adminUsername Username of the administrator performing the reset
//     * @param userId ID of the user whose password is being reset
//     * @return Plaintext temporary password (ONLY time this is allowed)
//     * @throws UserNotFoundException if user not found
//     * @throws InsufficientPermissionException if admin lacks permission
//     */
//    @Transactional
//    public String resetUserPassword(String adminUsername, Long userId) {
//        log.info("Admin {} requesting password reset for user ID: {}", adminUsername, userId);
//
//        // Find target user
//        User targetUser = userRepository.findById(userId)
//                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + userId));
//
//        // Verify admin permissions using verifyAdminPermission
//        verifyAdminPermission(adminUsername, targetUser);
//
//        // Generate 8-character temporary password
//        String temporaryPassword = generateTemporaryPassword();
//
//        // Encode password before saving
//        targetUser.setPassword(passwordEncoder.encode(temporaryPassword));
//
//        // Set mustChangePassword = true
//        targetUser.setMustChangePassword(true);
//
//        userRepository.save(targetUser);
//
//        // Log reset action with admin username (NOT the password)
//        log.info("Password reset successfully by admin {} for user: {}",
//                adminUsername, targetUser.getUsername());
//
//        // Return plaintext temporary password (only time this is allowed)
//        return temporaryPassword;
//    }
//
//    /**
//     * Validate password meets minimum requirements
//     *
//     * Current requirements:
//     * - Minimum 6 characters
//     *
//     * @param password Password to validate
//     * @throws InvalidUserOperationException if password does not meet requirements
//     */
//    private void validatePasswordRequirements(String password) {
//        // Check minimum 6 characters
//        if (password == null || password.length() < 6) {
//            throw new InvalidUserOperationException(
//                    "Password must be at least 6 characters long");
//        }
//    }
//
//    /**
//     * Generate a secure temporary password
//     *
//     * SECURITY NOTE: This password is generated using SecureRandom for cryptographic strength.
//     * The password includes uppercase letters, lowercase letters, and digits for complexity.
//     *
//     * @return 8-character temporary password in plaintext
//     */
//    private String generateTemporaryPassword() {
//        // Character sets for password generation
//        String uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
//        String lowercase = "abcdefghijklmnopqrstuvwxyz";
//        String digits = "0123456789";
//        String allCharacters = uppercase + lowercase + digits;
//
//        // Use SecureRandom for cryptographically strong random generation
//        SecureRandom random = new SecureRandom();
//        StringBuilder password = new StringBuilder(8);
//
//        // Ensure at least one of each character type
//        password.append(uppercase.charAt(random.nextInt(uppercase.length())));
//        password.append(lowercase.charAt(random.nextInt(lowercase.length())));
//        password.append(digits.charAt(random.nextInt(digits.length())));
//
//        // Fill remaining 5 characters randomly
//        for (int i = 3; i < 8; i++) {
//            password.append(allCharacters.charAt(random.nextInt(allCharacters.length())));
//        }
//
//        // Shuffle the password to randomize character positions
//        char[] passwordArray = password.toString().toCharArray();
//        for (int i = passwordArray.length - 1; i > 0; i--) {
//            int j = random.nextInt(i + 1);
//            char temp = passwordArray[i];
//            passwordArray[i] = passwordArray[j];
//            passwordArray[j] = temp;
//        }
//
//        return new String(passwordArray);
//    }
//
//    // ============================================================================
//    // EXISTING USER MANAGEMENT METHODS (continued)
//    // ============================================================================
//
//    /**
//     * Update user role (admin operation)
//     * Enforces permission hierarchy: SUPER_ADMIN > ADMIN > others
//     *
//     * @param adminUsername Username of the admin performing the operation
//     * @param userId User ID to update
//     * @param newRoleStr New role as string
//     * @return Updated user details
//     * @throws UserNotFoundException if user or admin not found
//     * @throws InsufficientPermissionException if admin lacks permission
//     * @throws InvalidUserOperationException if invalid role or transition
//     */
//    @Transactional
//    public UserResponseDTO updateUserRole(String adminUsername, Long userId, String newRoleStr) {
//        log.info("Admin {} updating role for user ID: {}", adminUsername, userId);
//
//        User targetUser = userRepository.findById(userId)
//                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + userId));
//
//        // Verify admin has permission to modify this user
//        verifyAdminPermission(adminUsername, targetUser);
//
//        // Parse and validate new role
//        User.Role newRole;
//        try {
//            newRole = User.Role.valueOf(newRoleStr.toUpperCase());
//        } catch (IllegalArgumentException e) {
//            log.error("Invalid role: {}", newRoleStr);
//            throw new InvalidUserOperationException("Invalid role: " + newRoleStr);
//        }
//
//        User.Role oldRole = targetUser.getRole();
//
//        // Update role
//        targetUser.setRole(newRole);
//
//        // Validate and handle branch requirements for new role
//        if (newRole == User.Role.BRANCH_MANAGER ||
//                newRole == User.Role.LOAN_OFFICER ||
//                newRole == User.Role.CARD_OFFICER ||
//                newRole == User.Role.EMPLOYEE) {
//            if (targetUser.getBranch() == null) {
//                log.warn("Role {} requires branch assignment but user {} has no branch",
//                        newRole, targetUser.getUsername());
//                throw new InvalidUserOperationException(
//                        newRole + " requires branch assignment. Please assign a branch first.");
//            }
//        } else if (newRole == User.Role.ADMIN ||
//                newRole == User.Role.SUPER_ADMIN ||
//                newRole == User.Role.CUSTOMER) {
//            // These roles should not have branch assignment
//            if (targetUser.getBranch() != null) {
//                log.info("Removing branch assignment for role {}", newRole);
//                targetUser.setBranch(null);
//            }
//        }
//
//        targetUser = userRepository.save(targetUser);
//
//        log.info("Admin {} updated user {} role from {} to {}",
//                adminUsername, targetUser.getUsername(), oldRole, newRole);
//
//        return mapToResponseDTO(targetUser);
//    }
//
//    /**
//     * Update user's branch assignment (admin operation)
//     *
//     * @param adminUsername Username of the admin performing the operation
//     * @param userId User ID to update
//     * @param newBranchId New branch ID
//     * @return Updated user details
//     * @throws UserNotFoundException if user not found
//     * @throws ResourceNotFoundException if branch not found
//     * @throws InsufficientPermissionException if admin lacks permission
//     * @throws InvalidUserOperationException if role doesn't require branch
//     */
//    @Transactional
//    public UserResponseDTO updateBranchId(String adminUsername, Long userId, Long newBranchId) {
//        log.info("Admin {} updating branch for user ID: {} to branch ID: {}",
//                adminUsername, userId, newBranchId);
//
//        User targetUser = userRepository.findById(userId)
//                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + userId));
//
//        // Verify admin has permission to modify this user
//        verifyAdminPermission(adminUsername, targetUser);
//
//        // Find and validate new branch
//        Branch newBranch = branchRepository.findById(newBranchId)
//                .orElseThrow(() -> new ResourceNotFoundException("Branch not found with ID: " + newBranchId));
//
//        if (newBranch.getStatus() != Branch.BranchStatus.ACTIVE) {
//            log.warn("Attempted to assign user to inactive branch: {}", newBranch.getBranchCode());
//            throw new InvalidUserOperationException(
//                    "Cannot assign user to inactive branch: " + newBranch.getBranchCode());
//        }
//
//        // Validate role requires branch assignment
//        User.Role role = targetUser.getRole();
//        if (role == User.Role.ADMIN || role == User.Role.SUPER_ADMIN || role == User.Role.CUSTOMER) {
//            log.warn("Attempted to assign branch to role {} which should not have branch", role);
//            throw new InvalidUserOperationException(
//                    role + " should not be assigned to a branch");
//        }
//
//        String oldBranchCode = targetUser.getBranch() != null ?
//                targetUser.getBranch().getBranchCode() : "N/A";
//
//        targetUser.setBranch(newBranch);
//        targetUser = userRepository.save(targetUser);
//
//        log.info("Admin {} updated user {} branch from {} to {}",
//                adminUsername, targetUser.getUsername(), oldBranchCode, newBranch.getBranchCode());
//
//        return mapToResponseDTO(targetUser);
//    }
//
//    /**
//     * Update user email (admin operation)
//     *
//     * @param adminUsername Username of the admin performing the operation
//     * @param userId User ID to update
//     * @param newEmail New email address
//     * @return Updated user details
//     * @throws UserNotFoundException if user not found
//     * @throws UserAlreadyExistsException if email already exists
//     * @throws InsufficientPermissionException if admin lacks permission
//     */
//    @Transactional
//    public UserResponseDTO updateUserEmail(String adminUsername, Long userId, String newEmail) {
//        log.info("Admin {} updating email for user ID: {}", adminUsername, userId);
//
//        User targetUser = userRepository.findById(userId)
//                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + userId));
//
//        // Verify admin has permission to modify this user
//        verifyAdminPermission(adminUsername, targetUser);
//
//        // Validate email format and uniqueness
//        if (newEmail == null || newEmail.trim().isEmpty()) {
//            throw new InvalidUserOperationException("Email cannot be empty");
//        }
//
//        if (!newEmail.matches("^[A-Za-z0-9+_.-]+@(.+)$")) {
//            throw new InvalidUserOperationException("Invalid email format");
//        }
//
//        if (!targetUser.getEmail().equals(newEmail) && userRepository.existsByEmail(newEmail)) {
//            log.warn("Email already exists: {}", newEmail);
//            throw new UserAlreadyExistsException("Email already exists: " + newEmail);
//        }
//
//        String oldEmail = targetUser.getEmail();
//        targetUser.setEmail(newEmail);
//        targetUser = userRepository.save(targetUser);
//
//        log.info("Admin {} updated user {} email from {} to {}",
//                adminUsername, targetUser.getUsername(), oldEmail, newEmail);
//
//        return mapToResponseDTO(targetUser);
//    }
//
//    /**
//     * Update user phone number (admin operation)
//     * Note: Requires adding phone field to User entity
//     *
//     * @param adminUsername Username of the admin performing the operation
//     * @param userId User ID to update
//     * @param newPhone New phone number
//     * @return Updated user details
//     * @throws UserNotFoundException if user not found
//     * @throws InsufficientPermissionException if admin lacks permission
//     * @throws InvalidUserOperationException if invalid phone format
//     */
//    @Transactional
//    public UserResponseDTO updateUserPhone(String adminUsername, Long userId, String newPhone) {
//        log.info("Admin {} updating phone for user ID: {}", adminUsername, userId);
//
//        User targetUser = userRepository.findById(userId)
//                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + userId));
//
//        // Verify admin has permission to modify this user
//        verifyAdminPermission(adminUsername, targetUser);
//
//        // Validate phone format
//        if (newPhone == null || newPhone.trim().isEmpty()) {
//            throw new InvalidUserOperationException("Phone number cannot be empty");
//        }
//
//        if (!newPhone.matches("^\\+?[1-9]\\d{1,14}$")) {
//            throw new InvalidUserOperationException("Invalid phone number format");
//        }
//
//        // Note: This assumes User entity has a phone field
//        // If not, this method should be removed or User entity should be extended
//        log.warn("Phone update requested but User entity may not have phone field");
//        log.info("Admin {} requested phone update for user {} to {}",
//                adminUsername, targetUser.getUsername(), newPhone);
//
//        // Placeholder - actual implementation requires User entity modification
//        throw new InvalidUserOperationException(
//                "Phone number management not yet implemented for User entity");
//    }
//
//    /**
//     * Promote user to new role with branch assignment (admin operation)
//     * Combines role and branch update in single atomic transaction
//     *
//     * @param adminUsername Username of the admin performing the operation
//     * @param userId User ID to promote
//     * @param newRoleStr New role as string
//     * @param newBranchId New branch ID (can be null for non-branch roles)
//     * @return Updated user details
//     * @throws UserNotFoundException if user not found
//     * @throws ResourceNotFoundException if branch not found
//     * @throws InsufficientPermissionException if admin lacks permission
//     * @throws InvalidUserOperationException if invalid promotion
//     */
//    @Transactional
//    public UserResponseDTO promoteUser(String adminUsername, Long userId, String newRoleStr, Long newBranchId) {
//        log.info("Admin {} promoting user ID: {} to role {} with branch ID: {}",
//                adminUsername, userId, newRoleStr, newBranchId);
//
//        User targetUser = userRepository.findById(userId)
//                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + userId));
//
//        // Verify admin has permission to modify this user
//        verifyAdminPermission(adminUsername, targetUser);
//
//        // Parse and validate new role
//        User.Role newRole;
//        try {
//            newRole = User.Role.valueOf(newRoleStr.toUpperCase());
//        } catch (IllegalArgumentException e) {
//            log.error("Invalid role: {}", newRoleStr);
//            throw new InvalidUserOperationException("Invalid role: " + newRoleStr);
//        }
//
//        User.Role oldRole = targetUser.getRole();
//        String oldBranchCode = targetUser.getBranch() != null ?
//                targetUser.getBranch().getBranchCode() : "N/A";
//
//        // Handle branch assignment based on new role
//        if (newRole == User.Role.BRANCH_MANAGER ||
//                newRole == User.Role.LOAN_OFFICER ||
//                newRole == User.Role.CARD_OFFICER ||
//                newRole == User.Role.EMPLOYEE) {
//
//            if (newBranchId == null) {
//                throw new InvalidUserOperationException(
//                        newRole + " requires branch assignment");
//            }
//
//            Branch newBranch = branchRepository.findById(newBranchId)
//                    .orElseThrow(() -> new ResourceNotFoundException(
//                            "Branch not found with ID: " + newBranchId));
//
//            if (newBranch.getStatus() != Branch.BranchStatus.ACTIVE) {
//                throw new InvalidUserOperationException(
//                        "Cannot assign user to inactive branch: " + newBranch.getBranchCode());
//            }
//
//            targetUser.setBranch(newBranch);
//
//        } else if (newRole == User.Role.ADMIN ||
//                newRole == User.Role.SUPER_ADMIN ||
//                newRole == User.Role.CUSTOMER) {
//            // These roles should not have branch
//            targetUser.setBranch(null);
//        }
//
//        // Update role
//        targetUser.setRole(newRole);
//
//        // Ensure user is active after promotion
//        if (targetUser.getUserStatus() != User.UserStatus.ACTIVE) {
//            targetUser.setUserStatus(User.UserStatus.ACTIVE);
//            targetUser.setIsActive(true);
//        }
//
//        targetUser = userRepository.save(targetUser);
//
//        log.info("Admin {} promoted user {} from {} ({}) to {} ({})",
//                adminUsername, targetUser.getUsername(), oldRole, oldBranchCode,
//                newRole, targetUser.getBranch() != null ? targetUser.getBranch().getBranchCode() : "N/A");
//
//        return mapToResponseDTO(targetUser);
//    }
//
//    /**
//     * Deactivate a user account (admin operation)
//     * Prevents deactivation of SUPER_ADMIN and last active ADMIN
//     *
//     * @param adminUsername Username of the admin performing the operation
//     * @param userId User ID to deactivate
//     * @throws UserNotFoundException if user not found
//     * @throws InsufficientPermissionException if admin lacks permission
//     * @throws InvalidUserOperationException if user cannot be deactivated
//     */
//    @Transactional
//    public void deactivateUser(String adminUsername, Long userId) {
//        log.info("Admin {} deactivating user ID: {}", adminUsername, userId);
//
//        User admin = userRepository.findByUsername(adminUsername)
//                .orElseThrow(() -> new UserNotFoundException("Admin user not found: " + adminUsername));
//
//        User targetUser = userRepository.findById(userId)
//                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + userId));
//
//        // Prevent self-deactivation
//        if (admin.getId().equals(targetUser.getId())) {
//            log.warn("Admin {} attempted to deactivate themselves", adminUsername);
//            throw new InvalidUserOperationException("Cannot deactivate your own account");
//        }
//
//        // Verify admin has permission to modify this user
//        verifyAdminPermission(adminUsername, targetUser);
//
//        // Validate user can be deactivated
//        validateUserCanBeDeactivated(targetUser);
//
//        targetUser.setUserStatus(User.UserStatus.INACTIVE);
//        targetUser.setIsActive(false);
//
//        userRepository.save(targetUser);
//
//        log.info("Admin {} deactivated user {}", adminUsername, targetUser.getUsername());
//    }
//
//    /**
//     * Reactivate a deactivated user account (admin operation)
//     *
//     * @param adminUsername Username of the admin performing the operation
//     * @param userId User ID to reactivate
//     * @return Updated user details
//     * @throws UserNotFoundException if user not found
//     * @throws InsufficientPermissionException if admin lacks permission
//     */
//    @Transactional
//    public UserResponseDTO reactivateUser(String adminUsername, Long userId) {
//        log.info("Admin {} reactivating user ID: {}", adminUsername, userId);
//
//        User targetUser = userRepository.findById(userId)
//                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + userId));
//
//        // Verify admin has permission to modify this user
//        verifyAdminPermission(adminUsername, targetUser);
//
//        targetUser.setUserStatus(User.UserStatus.ACTIVE);
//        targetUser.setIsActive(true);
//
//        targetUser = userRepository.save(targetUser);
//
//        log.info("Admin {} reactivated user {}", adminUsername, targetUser.getUsername());
//
//        return mapToResponseDTO(targetUser);
//    }
//
//    /**
//     * Get all users in a specific branch
//     *
//     * @param branchId Branch ID
//     * @return List of users in the branch
//     * @throws ResourceNotFoundException if branch not found
//     */
//    @Transactional(readOnly = true)
//    public List<UserResponseDTO> getUsersByBranch(Long branchId) {
//        log.info("Fetching users for branch ID: {}", branchId);
//
//        // Verify branch exists
//        branchRepository.findById(branchId)
//                .orElseThrow(() -> new ResourceNotFoundException("Branch not found with ID: " + branchId));
//
//        List<User> users = userRepository.findByBranchId(branchId);
//
//        log.info("Retrieved {} users for branch ID: {}", users.size(), branchId);
//
//        return users.stream()
//                .map(this::mapToResponseDTO)
//                .collect(Collectors.toList());
//    }
//
//    /**
//     * Get all users with a specific status
//     *
//     * @param status User status (PENDING, ACTIVE, INACTIVE)
//     * @return List of users with the specified status
//     * @throws InvalidUserOperationException if invalid status
//     */
//    @Transactional(readOnly = true)
//    public List<UserResponseDTO> getUsersByStatus(String status) {
//        log.info("Fetching users by status: {}", status);
//
//        User.UserStatus userStatus;
//        try {
//            userStatus = User.UserStatus.valueOf(status.toUpperCase());
//        } catch (IllegalArgumentException e) {
//            log.error("Invalid user status: {}", status);
//            throw new InvalidUserOperationException("Invalid user status: " + status);
//        }
//
//        List<User> users = userRepository.findByUserStatus(userStatus);
//
//        log.info("Retrieved {} users with status {}", users.size(), status);
//
//        return users.stream()
//                .map(this::mapToResponseDTO)
//                .collect(Collectors.toList());
//    }
//
//    // ============================================================================
//    // PRIVATE HELPER METHODS
//    // ============================================================================
//
//    /**
//     * Map User entity to UserResponseDTO
//     *
//     * @param user User entity
//     * @return UserResponseDTO
//     */
//    private UserResponseDTO mapToResponseDTO(User user) {
//        UserResponseDTO dto = new UserResponseDTO();
//        dto.setId(user.getId());
//        dto.setUsername(user.getUsername());
//        dto.setEmail(user.getEmail());
//        dto.setRole(user.getRole().name());
//        dto.setUserStatus(user.getUserStatus() != null ? user.getUserStatus().name() : null);
//        dto.setIsActive(user.getIsActive());
//        dto.setMustChangePassword(user.getMustChangePassword());
//
//        if (user.getBranch() != null) {
//            dto.setBranchId(user.getBranch().getId());
//            dto.setBranchCode(user.getBranch().getBranchCode());
//            dto.setBranchName(user.getBranch().getBranchName());
//        }
//
//        dto.setApprovalReason(user.getApprovalReason());
//        dto.setApprovedBy(user.getApprovedBy());
//        dto.setApprovedDate(user.getApprovedDate());
//        dto.setCreatedDate(user.getCreatedDate());
//        dto.setLastModified(user.getLastModified());
//
//        return dto;
//    }
//
//    /**
//     * Map User entity to PendingUserResponseDTO
//     *
//     * @param user User entity
//     * @return PendingUserResponseDTO
//     */
//    private PendingUserResponseDTO mapToPendingUserDTO(User user) {
//        PendingUserResponseDTO dto = new PendingUserResponseDTO();
//        dto.setId(user.getId());
//        dto.setUsername(user.getUsername());
//        dto.setEmail(user.getEmail());
//        dto.setRole(user.getRole().name());
//        dto.setUserStatus(user.getUserStatus() != null ? user.getUserStatus().name() : null);
//        dto.setBranchCode(user.getBranch() != null ? user.getBranch().getBranchCode() : null);
//        dto.setBranchName(user.getBranch() != null ? user.getBranch().getBranchName() : null);
//        dto.setCreatedDate(user.getCreatedDate());
//        dto.setApprovalReason(user.getApprovalReason());
//
//        return dto;
//    }
//
//    /**
//     * Verify admin has permission to modify target user
//     * Implements permission hierarchy: SUPER_ADMIN > ADMIN > others
//     *
//     * @param adminUsername Admin username
//     * @param targetUser Target user to be modified
//     * @throws UserNotFoundException if admin not found
//     * @throws InsufficientPermissionException if insufficient permission
//     */
//    private void verifyAdminPermission(String adminUsername, User targetUser) {
//        User admin = userRepository.findByUsername(adminUsername)
//                .orElseThrow(() -> new UserNotFoundException("Admin user not found: " + adminUsername));
//
//        // SUPER_ADMIN can modify anyone
//        if (admin.getRole() == User.Role.SUPER_ADMIN) {
//            log.debug("SUPER_ADMIN {} has permission to modify user {}",
//                    adminUsername, targetUser.getUsername());
//            return;
//        }
//
//        // ADMIN cannot modify SUPER_ADMIN or other ADMINs
//        if (admin.getRole() == User.Role.ADMIN) {
//            if (targetUser.getRole() == User.Role.SUPER_ADMIN) {
//                log.warn("ADMIN {} attempted to modify SUPER_ADMIN user {}",
//                        adminUsername, targetUser.getUsername());
//                throw new InsufficientPermissionException(
//                        "Admin cannot modify Super Admin accounts");
//            }
//
//            if (targetUser.getRole() == User.Role.ADMIN) {
//                log.warn("ADMIN {} attempted to modify another ADMIN user {}",
//                        adminUsername, targetUser.getUsername());
//                throw new InsufficientPermissionException(
//                        "Admin cannot modify other Admin accounts");
//            }
//
//            log.debug("ADMIN {} has permission to modify user {}",
//                    adminUsername, targetUser.getUsername());
//            return;
//        }
//
//        // All other roles cannot perform admin operations
//        log.warn("User {} with role {} attempted admin operation on user {}",
//                adminUsername, admin.getRole(), targetUser.getUsername());
//        throw new InsufficientPermissionException(
//                "Insufficient permissions to perform this operation");
//    }
//
//    /**
//     * Validate user can be deactivated
//     * Prevents deactivation of SUPER_ADMIN and last active ADMIN
//     *
//     * @param user User to validate
//     * @throws InvalidUserOperationException if user cannot be deactivated
//     */
//    private void validateUserCanBeDeactivated(User user) {
//        // Prevent deactivation of SUPER_ADMIN
//        if (user.getRole() == User.Role.SUPER_ADMIN) {
//            log.warn("Attempted to deactivate SUPER_ADMIN user: {}", user.getUsername());
//            throw new InvalidUserOperationException(
//                    "Super Admin accounts cannot be deactivated");
//        }
//
//        // Prevent deactivation of last active ADMIN
//        if (user.getRole() == User.Role.ADMIN) {
//            long activeAdminCount = userRepository.findByRole(User.Role.ADMIN).stream()
//                    .filter(u -> u.getUserStatus() == User.UserStatus.ACTIVE && u.getIsActive())
//                    .count();
//
//            if (activeAdminCount <= 1) {
//                log.warn("Attempted to deactivate the last active ADMIN user: {}", user.getUsername());
//                throw new InvalidUserOperationException(
//                        "Cannot deactivate the last active Admin account");
//            }
//        }
//    }
//
//
//    // ============================================================================
//// ADDITIONAL METHOD TO ADD TO UserManagementService.java
//// Add this method to the UserManagementService class
//// ============================================================================
//
//    /**
//     * Get user details by username
//     *
//     * This method supports the /api/users/me endpoint for retrieving
//     * the current authenticated user's profile.
//     *
//     * @param username Username to look up
//     * @return UserResponseDTO with user details
//     * @throws UserNotFoundException if user not found
//     */
//    @Transactional(readOnly = true)
//    public UserResponseDTO getUserByUsername(String username) {
//        log.info("Fetching user by username: {}", username);
//
//        User user = userRepository.findByUsername(username)
//                .orElseThrow(() -> new UserNotFoundException("User not found with username: " + username));
//
//        return mapToResponseDTO(user);
//    }
//}











//=========================================================================
//                         ANCIENT VERSION
//=========================================================================











//package com.izak.demoBankManagement.service;
//
//import com.izak.demoBankManagement.dto.*;
//import com.izak.demoBankManagement.entity.Branch;
//import com.izak.demoBankManagement.entity.Customer;
//import com.izak.demoBankManagement.entity.User;
//import com.izak.demoBankManagement.exception.*;
//import com.izak.demoBankManagement.repository.BranchRepository;
//import com.izak.demoBankManagement.repository.CustomerRepository;
//import com.izak.demoBankManagement.repository.UserRepository;
//import lombok.RequiredArgsConstructor;
//import lombok.extern.slf4j.Slf4j;
//import org.springframework.security.crypto.password.PasswordEncoder;
//import org.springframework.stereotype.Service;
//import org.springframework.transaction.annotation.Transactional;
//
//import java.time.LocalDateTime;
//import java.util.List;
//import java.util.stream.Collectors;
//
///**
// * Service for managing user accounts and approval workflows.
// * Handles user registration, approval/rejection, and user queries.
// */
//@Service
//@RequiredArgsConstructor
//@Slf4j
//public class UserManagementService {
//
//    private final UserRepository userRepository;
//    private final BranchRepository branchRepository;
//    private final CustomerRepository customerRepository;
//    private final PasswordEncoder passwordEncoder;
//    private final BranchAuthorizationService branchAuthorizationService;
//
//    /**
//     * Register a new user with PENDING status
//     * Only CUSTOMER and EMPLOYEE roles are allowed for self-registration
//     * Higher roles (ADMIN, SUPER_ADMIN) must be assigned by administrators
//     *
//     * @param request User registration details
//     * @return UserResponseDTO with created user details
//     * @throws UserAlreadyExistsException if username or email already exists
//     * @throws InvalidUserOperationException if invalid role or missing branch for EMPLOYEE
//     * @throws ResourceNotFoundException if branch not found
//     */
//    @Transactional
//    public UserResponseDTO registerUser(UserRegistrationRequestDTO request) {
//        log.info("Registering new user: {}", request.getUsername());
//
//        // Validate username uniqueness
//        if (userRepository.existsByUsername(request.getUsername())) {
//            log.warn("Username already exists: {}", request.getUsername());
//            throw new UserAlreadyExistsException("Username already exists: " + request.getUsername());
//        }
//
//        // Validate email uniqueness
//        if (userRepository.existsByEmail(request.getEmail())) {
//            log.warn("Email already exists: {}", request.getEmail());
//            throw new UserAlreadyExistsException("Email already exists: " + request.getEmail());
//        }
//
//        // Validate role restriction for self-registration
//        User.Role role;
//        try {
//            role = User.Role.valueOf(request.getRole().toUpperCase());
//        } catch (IllegalArgumentException e) {
//            log.error("Invalid role: {}", request.getRole());
//            throw new InvalidUserOperationException("Invalid role: " + request.getRole());
//        }
//
//        if (role != User.Role.CUSTOMER && role != User.Role.EMPLOYEE) {
//            log.warn("Attempted self-registration with restricted role: {}", role);
//            throw new InvalidUserOperationException(
//                    "Self-registration is only allowed for CUSTOMER and EMPLOYEE roles. " +
//                            "Higher roles must be assigned by administrators.");
//        }
//
//        // Create new user
//        User user = new User();
//        user.setUsername(request.getUsername());
//        user.setPassword(passwordEncoder.encode(request.getPassword()));
//        user.setEmail(request.getEmail());
//        user.setRole(role);
//        user.setUserStatus(User.UserStatus.PENDING); // Default to PENDING for approval workflow
//        user.setIsActive(false); // Inactive until approved
//        user.setMustChangePassword(false);
//
//        // Handle branch assignment for EMPLOYEE role
//        if (role == User.Role.EMPLOYEE) {
//            if (request.getBranchCode() != null && !request.getBranchCode().trim().isEmpty()) {
//                Branch branch = branchRepository.findByBranchCode(request.getBranchCode())
//                        .orElseThrow(() -> new ResourceNotFoundException(
//                                "Branch not found with code: " + request.getBranchCode()));
//
//                if (branch.getStatus() != Branch.BranchStatus.ACTIVE) {
//                    log.warn("Attempted to assign user to inactive branch: {}", request.getBranchCode());
//                    throw new InvalidUserOperationException(
//                            "Cannot assign user to inactive branch: " + request.getBranchCode());
//                }
//
//                user.setBranch(branch);
//                log.info("Assigned user {} to branch {}", request.getUsername(), branch.getBranchCode());
//            } else {
//                log.info("EMPLOYEE registration without branch assignment - will require admin assignment");
//            }
//        }
//
//        user = userRepository.save(user);
//
//        log.info("User registered successfully: {} with status PENDING", user.getUsername());
//
//        return mapToResponseDTO(user);
//    }
//
//    /**
//     * Get all users with PENDING status awaiting approval
//     *
//     * @return List of pending users
//     */
//    @Transactional(readOnly = true)
//    public List<PendingUserResponseDTO> getPendingApprovals() {
//        log.info("Fetching all pending user approvals");
//
//        List<User> pendingUsers = userRepository.findByUserStatus(User.UserStatus.PENDING);
//
//        log.info("Found {} pending user approvals", pendingUsers.size());
//
//        return pendingUsers.stream()
//                .map(this::mapToPendingUserDTO)
//                .collect(Collectors.toList());
//    }
//
//    /**
//     * Approve a pending user and activate their account
//     * Can optionally override role and assign branch during approval
//     *
//     * @param adminUsername Username of the approving administrator
//     * @param request Approval request with optional role/branch assignment
//     * @return UserResponseDTO with updated user details
//     * @throws UserNotFoundException if user not found
//     * @throws InvalidUserOperationException if user not in PENDING status or invalid role/branch
//     * @throws ResourceNotFoundException if branch not found
//     */
//    @Transactional
//    public UserResponseDTO approveUser(String adminUsername, UserApprovalRequestDTO request) {
//        log.info("Admin {} approving user ID: {}", adminUsername, request.getUserId());
//
//        User user = userRepository.findById(request.getUserId())
//                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + request.getUserId()));
//
//        if (user.getUserStatus() != User.UserStatus.PENDING) {
//            log.warn("Attempted to approve user {} with status: {}", user.getUsername(), user.getUserStatus());
//            throw new InvalidUserOperationException(
//                    "User is not in PENDING status. Current status: " + user.getUserStatus());
//        }
//
//        // Override role if provided
//        if (request.getAssignedRole() != null && !request.getAssignedRole().trim().isEmpty()) {
//            try {
//                User.Role newRole = User.Role.valueOf(request.getAssignedRole().toUpperCase());
//                user.setRole(newRole);
//                log.info("Role updated from {} to {} during approval", user.getRole(), newRole);
//            } catch (IllegalArgumentException e) {
//                log.error("Invalid assigned role: {}", request.getAssignedRole());
//                throw new InvalidUserOperationException("Invalid role: " + request.getAssignedRole());
//            }
//        }
//
//        // Assign or update branch if provided
//        if (request.getBranchCode() != null && !request.getBranchCode().trim().isEmpty()) {
//            Branch branch = branchRepository.findByBranchCode(request.getBranchCode())
//                    .orElseThrow(() -> new ResourceNotFoundException(
//                            "Branch not found with code: " + request.getBranchCode()));
//
//            if (branch.getStatus() != Branch.BranchStatus.ACTIVE) {
//                log.warn("Attempted to assign user to inactive branch: {}", request.getBranchCode());
//                throw new InvalidUserOperationException(
//                        "Cannot assign user to inactive branch: " + request.getBranchCode());
//            }
//
//            user.setBranch(branch);
//            log.info("Branch assigned/updated to {} during approval", branch.getBranchCode());
//        }
//
//        // Validate branch assignment for certain roles
//        if ((user.getRole() == User.Role.BRANCH_MANAGER ||
//                user.getRole() == User.Role.LOAN_OFFICER ||
//                user.getRole() == User.Role.CARD_OFFICER) && user.getBranch() == null) {
//            log.warn("Attempted to approve {} without branch assignment", user.getRole());
//            throw new InvalidUserOperationException(
//                    user.getRole() + " must be assigned to a branch");
//        }
//
//        // Update approval fields
//        user.setUserStatus(User.UserStatus.ACTIVE);
//        user.setIsActive(true);
//        user.setApprovedBy(adminUsername);
//        user.setApprovedDate(LocalDateTime.now());
//        user.setApprovalReason(request.getReason());
//
//        user = userRepository.save(user);
//
//        log.info("User {} approved successfully by {}", user.getUsername(), adminUsername);
//
//        return mapToResponseDTO(user);
//    }
//
//    /**
//     * Reject a pending user registration
//     *
//     * @param adminUsername Username of the rejecting administrator
//     * @param userId User ID to reject
//     * @param reason Reason for rejection
//     * @throws UserNotFoundException if user not found
//     * @throws InvalidUserOperationException if user not in PENDING status
//     */
//    @Transactional
//    public void rejectUser(String adminUsername, Long userId, String reason) {
//        log.info("Admin {} rejecting user ID: {}", adminUsername, userId);
//
//        User user = userRepository.findById(userId)
//                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + userId));
//
//        if (user.getUserStatus() != User.UserStatus.PENDING) {
//            log.warn("Attempted to reject user {} with status: {}", user.getUsername(), user.getUserStatus());
//            throw new InvalidUserOperationException(
//                    "User is not in PENDING status. Current status: " + user.getUserStatus());
//        }
//
//        user.setUserStatus(User.UserStatus.INACTIVE);
//        user.setIsActive(false);
//        user.setApprovedBy(adminUsername);
//        user.setApprovedDate(LocalDateTime.now());
//        user.setApprovalReason(reason != null ? reason : "Registration rejected");
//
//        userRepository.save(user);
//
//        log.info("User {} rejected successfully by {}", user.getUsername(), adminUsername);
//    }
//
//    /**
//     * Get user details by ID
//     *
//     * @param userId User ID
//     * @return UserResponseDTO with user details
//     * @throws UserNotFoundException if user not found
//     */
//    @Transactional(readOnly = true)
//    public UserResponseDTO getUserById(Long userId) {
//        log.info("Fetching user by ID: {}", userId);
//
//        User user = userRepository.findById(userId)
//                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + userId));
//
//        return mapToResponseDTO(user);
//    }
//
//    /**
//     * Get all users in the system
//     *
//     * @return List of all users
//     */
//    @Transactional(readOnly = true)
//    public List<UserResponseDTO> getAllUsers() {
//        log.info("Fetching all users");
//
//        List<User> users = userRepository.findAll();
//
//        log.info("Retrieved {} users", users.size());
//
//        return users.stream()
//                .map(this::mapToResponseDTO)
//                .collect(Collectors.toList());
//    }
//
//    /**
//     * Get all users with a specific role
//     *
//     * @param role Role name (e.g., "ADMIN", "CUSTOMER")
//     * @return List of users with the specified role
//     * @throws InvalidUserOperationException if invalid role provided
//     */
//    @Transactional(readOnly = true)
//    public List<UserResponseDTO> getUsersByRole(String role) {
//        log.info("Fetching users by role: {}", role);
//
//        User.Role userRole;
//        try {
//            userRole = User.Role.valueOf(role.toUpperCase());
//        } catch (IllegalArgumentException e) {
//            log.error("Invalid role: {}", role);
//            throw new InvalidUserOperationException("Invalid role: " + role);
//        }
//
//        List<User> users = userRepository.findByRole(userRole);
//
//        log.info("Retrieved {} users with role {}", users.size(), role);
//
//        return users.stream()
//                .map(this::mapToResponseDTO)
//                .collect(Collectors.toList());
//    }
//
//    /**
//     * Update user details (admin operation)
//     *
//     * @param userId User ID to update
//     * @param request Update request with new values
//     * @return Updated user details
//     * @throws UserNotFoundException if user not found
//     * @throws UserAlreadyExistsException if email already exists for another user
//     * @throws InvalidUserOperationException if invalid role or branch
//     * @throws ResourceNotFoundException if branch not found
//     */
//    @Transactional
//    public UserResponseDTO updateUser(Long userId, UserUpdateRequestDTO request) {
//        log.info("Updating user ID: {}", userId);
//
//        User user = userRepository.findById(userId)
//                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + userId));
//
//        // Update email if provided
//        if (request.getEmail() != null && !request.getEmail().trim().isEmpty()) {
//            if (!user.getEmail().equals(request.getEmail()) &&
//                    userRepository.existsByEmail(request.getEmail())) {
//                log.warn("Email already exists: {}", request.getEmail());
//                throw new UserAlreadyExistsException("Email already exists: " + request.getEmail());
//            }
//            user.setEmail(request.getEmail());
//        }
//
//        // Update role if provided
//        if (request.getRole() != null && !request.getRole().trim().isEmpty()) {
//            try {
//                User.Role newRole = User.Role.valueOf(request.getRole().toUpperCase());
//                user.setRole(newRole);
//                log.info("Role updated to {}", newRole);
//            } catch (IllegalArgumentException e) {
//                log.error("Invalid role: {}", request.getRole());
//                throw new InvalidUserOperationException("Invalid role: " + request.getRole());
//            }
//        }
//
//        // Update user status if provided
//        if (request.getUserStatus() != null && !request.getUserStatus().trim().isEmpty()) {
//            try {
//                User.UserStatus newStatus = User.UserStatus.valueOf(request.getUserStatus().toUpperCase());
//                user.setUserStatus(newStatus);
//                log.info("User status updated to {}", newStatus);
//            } catch (IllegalArgumentException e) {
//                log.error("Invalid user status: {}", request.getUserStatus());
//                throw new InvalidUserOperationException("Invalid user status: " + request.getUserStatus());
//            }
//        }
//
//        // Update isActive if provided
//        if (request.getIsActive() != null) {
//            user.setIsActive(request.getIsActive());
//        }
//
//        // Update mustChangePassword if provided
//        if (request.getMustChangePassword() != null) {
//            user.setMustChangePassword(request.getMustChangePassword());
//        }
//
//        // Update branch if provided
//        if (request.getBranchCode() != null && !request.getBranchCode().trim().isEmpty()) {
//            Branch branch = branchRepository.findByBranchCode(request.getBranchCode())
//                    .orElseThrow(() -> new ResourceNotFoundException(
//                            "Branch not found with code: " + request.getBranchCode()));
//
//            if (branch.getStatus() != Branch.BranchStatus.ACTIVE) {
//                log.warn("Attempted to assign user to inactive branch: {}", request.getBranchCode());
//                throw new InvalidUserOperationException(
//                        "Cannot assign user to inactive branch: " + request.getBranchCode());
//            }
//
//            user.setBranch(branch);
//            log.info("Branch updated to {}", branch.getBranchCode());
//        }
//
//        user = userRepository.save(user);
//
//        log.info("User {} updated successfully", user.getUsername());
//
//        return mapToResponseDTO(user);
//    }
//
//    /**
//     * Change user password
//     *
//     * @param userId User ID
//     * @param request Password change request
//     * @throws UserNotFoundException if user not found
//     * @throws InvalidUserOperationException if current password incorrect or passwords don't match
//     */
//    @Transactional
//    public void changePassword(Long userId, PasswordChangeRequestDTO request) {
//        log.info("Changing password for user ID: {}", userId);
//
//        User user = userRepository.findById(userId)
//                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + userId));
//
//        // Validate current password
//        if (!passwordEncoder.matches(request.getCurrentPassword(), user.getPassword())) {
//            log.warn("Invalid current password for user {}", user.getUsername());
//            throw new InvalidUserOperationException("Current password is incorrect");
//        }
//
//        // Validate new password confirmation
//        if (!request.getNewPassword().equals(request.getConfirmPassword())) {
//            log.warn("New password and confirmation do not match for user {}", user.getUsername());
//            throw new InvalidUserOperationException("New password and confirmation do not match");
//        }
//
//        // Validate new password is different from current
//        if (passwordEncoder.matches(request.getNewPassword(), user.getPassword())) {
//            log.warn("New password is same as current password for user {}", user.getUsername());
//            throw new InvalidUserOperationException("New password must be different from current password");
//        }
//
//        // Update password
//        user.setPassword(passwordEncoder.encode(request.getNewPassword()));
//        user.setMustChangePassword(false);
//
//        userRepository.save(user);
//
//        log.info("Password changed successfully for user {}", user.getUsername());
//    }
//
//    /**
//     * Map User entity to UserResponseDTO
//     *
//     * @param user User entity
//     * @return UserResponseDTO
//     */
//    private UserResponseDTO mapToResponseDTO(User user) {
//        UserResponseDTO dto = new UserResponseDTO();
//        dto.setId(user.getId());
//        dto.setUsername(user.getUsername());
//        dto.setEmail(user.getEmail());
//        dto.setRole(user.getRole().name());
//        dto.setUserStatus(user.getUserStatus() != null ? user.getUserStatus().name() : null);
//        dto.setIsActive(user.getIsActive());
//        dto.setMustChangePassword(user.getMustChangePassword());
//
//        if (user.getBranch() != null) {
//            dto.setBranchId(user.getBranch().getId());
//            dto.setBranchCode(user.getBranch().getBranchCode());
//            dto.setBranchName(user.getBranch().getBranchName());
//        }
//
//        dto.setApprovalReason(user.getApprovalReason());
//        dto.setApprovedBy(user.getApprovedBy());
//        dto.setApprovedDate(user.getApprovedDate());
//        dto.setCreatedDate(user.getCreatedDate());
//        dto.setLastModified(user.getLastModified());
//
//        return dto;
//    }
//
//    /**
//     * Map User entity to PendingUserResponseDTO
//     *
//     * @param user User entity
//     * @return PendingUserResponseDTO
//     */
//    private PendingUserResponseDTO mapToPendingUserDTO(User user) {
//        PendingUserResponseDTO dto = new PendingUserResponseDTO();
//        dto.setId(user.getId());
//        dto.setUsername(user.getUsername());
//        dto.setEmail(user.getEmail());
//        dto.setRole(user.getRole().name());
//        dto.setUserStatus(user.getUserStatus() != null ? user.getUserStatus().name() : null);
//        dto.setBranchCode(user.getBranch() != null ? user.getBranch().getBranchCode() : null);
//        dto.setBranchName(user.getBranch() != null ? user.getBranch().getBranchName() : null);
//        dto.setCreatedDate(user.getCreatedDate());
//        dto.setApprovalReason(user.getApprovalReason());
//
//        return dto;
//    }
//
//
//
//
//
//    // Add these methods to the existing UserManagementService class
//
//    /**
//     * Update user role (admin operation)
//     * Enforces permission hierarchy: SUPER_ADMIN > ADMIN > others
//     *
//     * @param adminUsername Username of the admin performing the operation
//     * @param userId User ID to update
//     * @param newRoleStr New role as string
//     * @return Updated user details
//     * @throws UserNotFoundException if user or admin not found
//     * @throws InsufficientPermissionException if admin lacks permission
//     * @throws InvalidUserOperationException if invalid role or transition
//     */
//    @Transactional
//    public UserResponseDTO updateUserRole(String adminUsername, Long userId, String newRoleStr) {
//        log.info("Admin {} updating role for user ID: {}", adminUsername, userId);
//
//        User targetUser = userRepository.findById(userId)
//                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + userId));
//
//        // Verify admin has permission to modify this user
//        verifyAdminPermission(adminUsername, targetUser);
//
//        // Parse and validate new role
//        User.Role newRole;
//        try {
//            newRole = User.Role.valueOf(newRoleStr.toUpperCase());
//        } catch (IllegalArgumentException e) {
//            log.error("Invalid role: {}", newRoleStr);
//            throw new InvalidUserOperationException("Invalid role: " + newRoleStr);
//        }
//
//        User.Role oldRole = targetUser.getRole();
//
//        // Update role
//        targetUser.setRole(newRole);
//
//        // Validate and handle branch requirements for new role
//        if (newRole == User.Role.BRANCH_MANAGER ||
//                newRole == User.Role.LOAN_OFFICER ||
//                newRole == User.Role.CARD_OFFICER ||
//                newRole == User.Role.EMPLOYEE) {
//            if (targetUser.getBranch() == null) {
//                log.warn("Role {} requires branch assignment but user {} has no branch",
//                        newRole, targetUser.getUsername());
//                throw new InvalidUserOperationException(
//                        newRole + " requires branch assignment. Please assign a branch first.");
//            }
//        } else if (newRole == User.Role.ADMIN ||
//                newRole == User.Role.SUPER_ADMIN ||
//                newRole == User.Role.CUSTOMER) {
//            // These roles should not have branch assignment
//            if (targetUser.getBranch() != null) {
//                log.info("Removing branch assignment for role {}", newRole);
//                targetUser.setBranch(null);
//            }
//        }
//
//        targetUser = userRepository.save(targetUser);
//
//        log.info("Admin {} updated user {} role from {} to {}",
//                adminUsername, targetUser.getUsername(), oldRole, newRole);
//
//        return mapToResponseDTO(targetUser);
//    }
//
//    /**
//     * Update user's branch assignment (admin operation)
//     *
//     * @param adminUsername Username of the admin performing the operation
//     * @param userId User ID to update
//     * @param newBranchId New branch ID
//     * @return Updated user details
//     * @throws UserNotFoundException if user not found
//     * @throws ResourceNotFoundException if branch not found
//     * @throws InsufficientPermissionException if admin lacks permission
//     * @throws InvalidUserOperationException if role doesn't require branch
//     */
//    @Transactional
//    public UserResponseDTO updateBranchId(String adminUsername, Long userId, Long newBranchId) {
//        log.info("Admin {} updating branch for user ID: {} to branch ID: {}",
//                adminUsername, userId, newBranchId);
//
//        User targetUser = userRepository.findById(userId)
//                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + userId));
//
//        // Verify admin has permission to modify this user
//        verifyAdminPermission(adminUsername, targetUser);
//
//        // Find and validate new branch
//        Branch newBranch = branchRepository.findById(newBranchId)
//                .orElseThrow(() -> new ResourceNotFoundException("Branch not found with ID: " + newBranchId));
//
//        if (newBranch.getStatus() != Branch.BranchStatus.ACTIVE) {
//            log.warn("Attempted to assign user to inactive branch: {}", newBranch.getBranchCode());
//            throw new InvalidUserOperationException(
//                    "Cannot assign user to inactive branch: " + newBranch.getBranchCode());
//        }
//
//        // Validate role requires branch assignment
//        User.Role role = targetUser.getRole();
//        if (role == User.Role.ADMIN || role == User.Role.SUPER_ADMIN || role == User.Role.CUSTOMER) {
//            log.warn("Attempted to assign branch to role {} which should not have branch", role);
//            throw new InvalidUserOperationException(
//                    role + " should not be assigned to a branch");
//        }
//
//        String oldBranchCode = targetUser.getBranch() != null ?
//                targetUser.getBranch().getBranchCode() : "N/A";
//
//        targetUser.setBranch(newBranch);
//        targetUser = userRepository.save(targetUser);
//
//        log.info("Admin {} updated user {} branch from {} to {}",
//                adminUsername, targetUser.getUsername(), oldBranchCode, newBranch.getBranchCode());
//
//        return mapToResponseDTO(targetUser);
//    }
//
//    /**
//     * Update user email (admin operation)
//     *
//     * @param adminUsername Username of the admin performing the operation
//     * @param userId User ID to update
//     * @param newEmail New email address
//     * @return Updated user details
//     * @throws UserNotFoundException if user not found
//     * @throws UserAlreadyExistsException if email already exists
//     * @throws InsufficientPermissionException if admin lacks permission
//     */
//    @Transactional
//    public UserResponseDTO updateUserEmail(String adminUsername, Long userId, String newEmail) {
//        log.info("Admin {} updating email for user ID: {}", adminUsername, userId);
//
//        User targetUser = userRepository.findById(userId)
//                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + userId));
//
//        // Verify admin has permission to modify this user
//        verifyAdminPermission(adminUsername, targetUser);
//
//        // Validate email format and uniqueness
//        if (newEmail == null || newEmail.trim().isEmpty()) {
//            throw new InvalidUserOperationException("Email cannot be empty");
//        }
//
//        if (!newEmail.matches("^[A-Za-z0-9+_.-]+@(.+)$")) {
//            throw new InvalidUserOperationException("Invalid email format");
//        }
//
//        if (!targetUser.getEmail().equals(newEmail) && userRepository.existsByEmail(newEmail)) {
//            log.warn("Email already exists: {}", newEmail);
//            throw new UserAlreadyExistsException("Email already exists: " + newEmail);
//        }
//
//        String oldEmail = targetUser.getEmail();
//        targetUser.setEmail(newEmail);
//        targetUser = userRepository.save(targetUser);
//
//        log.info("Admin {} updated user {} email from {} to {}",
//                adminUsername, targetUser.getUsername(), oldEmail, newEmail);
//
//        return mapToResponseDTO(targetUser);
//    }
//
//    /**
//     * Update user phone number (admin operation)
//     * Note: Requires adding phone field to User entity
//     *
//     * @param adminUsername Username of the admin performing the operation
//     * @param userId User ID to update
//     * @param newPhone New phone number
//     * @return Updated user details
//     * @throws UserNotFoundException if user not found
//     * @throws InsufficientPermissionException if admin lacks permission
//     * @throws InvalidUserOperationException if invalid phone format
//     */
//    @Transactional
//    public UserResponseDTO updateUserPhone(String adminUsername, Long userId, String newPhone) {
//        log.info("Admin {} updating phone for user ID: {}", adminUsername, userId);
//
//        User targetUser = userRepository.findById(userId)
//                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + userId));
//
//        // Verify admin has permission to modify this user
//        verifyAdminPermission(adminUsername, targetUser);
//
//        // Validate phone format
//        if (newPhone == null || newPhone.trim().isEmpty()) {
//            throw new InvalidUserOperationException("Phone number cannot be empty");
//        }
//
//        if (!newPhone.matches("^\\+?[1-9]\\d{1,14}$")) {
//            throw new InvalidUserOperationException("Invalid phone number format");
//        }
//
//        // Note: This assumes User entity has a phone field
//        // If not, this method should be removed or User entity should be extended
//        log.warn("Phone update requested but User entity may not have phone field");
//        log.info("Admin {} requested phone update for user {} to {}",
//                adminUsername, targetUser.getUsername(), newPhone);
//
//        // Placeholder - actual implementation requires User entity modification
//        throw new InvalidUserOperationException(
//                "Phone number management not yet implemented for User entity");
//    }
//
//    /**
//     * Promote user to new role with branch assignment (admin operation)
//     * Combines role and branch update in single atomic transaction
//     *
//     * @param adminUsername Username of the admin performing the operation
//     * @param userId User ID to promote
//     * @param newRoleStr New role as string
//     * @param newBranchId New branch ID (can be null for non-branch roles)
//     * @return Updated user details
//     * @throws UserNotFoundException if user not found
//     * @throws ResourceNotFoundException if branch not found
//     * @throws InsufficientPermissionException if admin lacks permission
//     * @throws InvalidUserOperationException if invalid promotion
//     */
//    @Transactional
//    public UserResponseDTO promoteUser(String adminUsername, Long userId, String newRoleStr, Long newBranchId) {
//        log.info("Admin {} promoting user ID: {} to role {} with branch ID: {}",
//                adminUsername, userId, newRoleStr, newBranchId);
//
//        User targetUser = userRepository.findById(userId)
//                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + userId));
//
//        // Verify admin has permission to modify this user
//        verifyAdminPermission(adminUsername, targetUser);
//
//        // Parse and validate new role
//        User.Role newRole;
//        try {
//            newRole = User.Role.valueOf(newRoleStr.toUpperCase());
//        } catch (IllegalArgumentException e) {
//            log.error("Invalid role: {}", newRoleStr);
//            throw new InvalidUserOperationException("Invalid role: " + newRoleStr);
//        }
//
//        User.Role oldRole = targetUser.getRole();
//        String oldBranchCode = targetUser.getBranch() != null ?
//                targetUser.getBranch().getBranchCode() : "N/A";
//
//        // Handle branch assignment based on new role
//        if (newRole == User.Role.BRANCH_MANAGER ||
//                newRole == User.Role.LOAN_OFFICER ||
//                newRole == User.Role.CARD_OFFICER ||
//                newRole == User.Role.EMPLOYEE) {
//
//            if (newBranchId == null) {
//                throw new InvalidUserOperationException(
//                        newRole + " requires branch assignment");
//            }
//
//            Branch newBranch = branchRepository.findById(newBranchId)
//                    .orElseThrow(() -> new ResourceNotFoundException(
//                            "Branch not found with ID: " + newBranchId));
//
//            if (newBranch.getStatus() != Branch.BranchStatus.ACTIVE) {
//                throw new InvalidUserOperationException(
//                        "Cannot assign user to inactive branch: " + newBranch.getBranchCode());
//            }
//
//            targetUser.setBranch(newBranch);
//
//        } else if (newRole == User.Role.ADMIN ||
//                newRole == User.Role.SUPER_ADMIN ||
//                newRole == User.Role.CUSTOMER) {
//            // These roles should not have branch
//            targetUser.setBranch(null);
//        }
//
//        // Update role
//        targetUser.setRole(newRole);
//
//        // Ensure user is active after promotion
//        if (targetUser.getUserStatus() != User.UserStatus.ACTIVE) {
//            targetUser.setUserStatus(User.UserStatus.ACTIVE);
//            targetUser.setIsActive(true);
//        }
//
//        targetUser = userRepository.save(targetUser);
//
//        log.info("Admin {} promoted user {} from {} ({}) to {} ({})",
//                adminUsername, targetUser.getUsername(), oldRole, oldBranchCode,
//                newRole, targetUser.getBranch() != null ? targetUser.getBranch().getBranchCode() : "N/A");
//
//        return mapToResponseDTO(targetUser);
//    }
//
//    /**
//     * Deactivate a user account (admin operation)
//     * Prevents deactivation of SUPER_ADMIN and last active ADMIN
//     *
//     * @param adminUsername Username of the admin performing the operation
//     * @param userId User ID to deactivate
//     * @throws UserNotFoundException if user not found
//     * @throws InsufficientPermissionException if admin lacks permission
//     * @throws InvalidUserOperationException if user cannot be deactivated
//     */
//    @Transactional
//    public void deactivateUser(String adminUsername, Long userId) {
//        log.info("Admin {} deactivating user ID: {}", adminUsername, userId);
//
//        User admin = userRepository.findByUsername(adminUsername)
//                .orElseThrow(() -> new UserNotFoundException("Admin user not found: " + adminUsername));
//
//        User targetUser = userRepository.findById(userId)
//                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + userId));
//
//        // Prevent self-deactivation
//        if (admin.getId().equals(targetUser.getId())) {
//            log.warn("Admin {} attempted to deactivate themselves", adminUsername);
//            throw new InvalidUserOperationException("Cannot deactivate your own account");
//        }
//
//        // Verify admin has permission to modify this user
//        verifyAdminPermission(adminUsername, targetUser);
//
//        // Validate user can be deactivated
//        validateUserCanBeDeactivated(targetUser);
//
//        targetUser.setUserStatus(User.UserStatus.INACTIVE);
//        targetUser.setIsActive(false);
//
//        userRepository.save(targetUser);
//
//        log.info("Admin {} deactivated user {}", adminUsername, targetUser.getUsername());
//    }
//
//    /**
//     * Reactivate a deactivated user account (admin operation)
//     *
//     * @param adminUsername Username of the admin performing the operation
//     * @param userId User ID to reactivate
//     * @return Updated user details
//     * @throws UserNotFoundException if user not found
//     * @throws InsufficientPermissionException if admin lacks permission
//     */
//    @Transactional
//    public UserResponseDTO reactivateUser(String adminUsername, Long userId) {
//        log.info("Admin {} reactivating user ID: {}", adminUsername, userId);
//
//        User targetUser = userRepository.findById(userId)
//                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + userId));
//
//        // Verify admin has permission to modify this user
//        verifyAdminPermission(adminUsername, targetUser);
//
//        targetUser.setUserStatus(User.UserStatus.ACTIVE);
//        targetUser.setIsActive(true);
//
//        targetUser = userRepository.save(targetUser);
//
//        log.info("Admin {} reactivated user {}", adminUsername, targetUser.getUsername());
//
//        return mapToResponseDTO(targetUser);
//    }
//
//    /**
//     * Get all users in a specific branch
//     *
//     * @param branchId Branch ID
//     * @return List of users in the branch
//     * @throws ResourceNotFoundException if branch not found
//     */
//    @Transactional(readOnly = true)
//    public List<UserResponseDTO> getUsersByBranch(Long branchId) {
//        log.info("Fetching users for branch ID: {}", branchId);
//
//        // Verify branch exists
//        branchRepository.findById(branchId)
//                .orElseThrow(() -> new ResourceNotFoundException("Branch not found with ID: " + branchId));
//
//        List<User> users = userRepository.findByBranchId(branchId);
//
//        log.info("Retrieved {} users for branch ID: {}", users.size(), branchId);
//
//        return users.stream()
//                .map(this::mapToResponseDTO)
//                .collect(Collectors.toList());
//    }
//
//    /**
//     * Get all users with a specific status
//     *
//     * @param status User status (PENDING, ACTIVE, INACTIVE)
//     * @return List of users with the specified status
//     * @throws InvalidUserOperationException if invalid status
//     */
//    @Transactional(readOnly = true)
//    public List<UserResponseDTO> getUsersByStatus(String status) {
//        log.info("Fetching users by status: {}", status);
//
//        User.UserStatus userStatus;
//        try {
//            userStatus = User.UserStatus.valueOf(status.toUpperCase());
//        } catch (IllegalArgumentException e) {
//            log.error("Invalid user status: {}", status);
//            throw new InvalidUserOperationException("Invalid user status: " + status);
//        }
//
//        List<User> users = userRepository.findByUserStatus(userStatus);
//
//        log.info("Retrieved {} users with status {}", users.size(), status);
//
//        return users.stream()
//                .map(this::mapToResponseDTO)
//                .collect(Collectors.toList());
//    }
//
//    /**
//     * Verify admin has permission to modify target user
//     * Implements permission hierarchy: SUPER_ADMIN > ADMIN > others
//     *
//     * @param adminUsername Admin username
//     * @param targetUser Target user to be modified
//     * @throws UserNotFoundException if admin not found
//     * @throws InsufficientPermissionException if insufficient permission
//     */
//    private void verifyAdminPermission(String adminUsername, User targetUser) {
//        User admin = userRepository.findByUsername(adminUsername)
//                .orElseThrow(() -> new UserNotFoundException("Admin user not found: " + adminUsername));
//
//        // SUPER_ADMIN can modify anyone
//        if (admin.getRole() == User.Role.SUPER_ADMIN) {
//            log.debug("SUPER_ADMIN {} has permission to modify user {}",
//                    adminUsername, targetUser.getUsername());
//            return;
//        }
//
//        // ADMIN cannot modify SUPER_ADMIN or other ADMINs
//        if (admin.getRole() == User.Role.ADMIN) {
//            if (targetUser.getRole() == User.Role.SUPER_ADMIN) {
//                log.warn("ADMIN {} attempted to modify SUPER_ADMIN user {}",
//                        adminUsername, targetUser.getUsername());
//                throw new InsufficientPermissionException(
//                        "Admin cannot modify Super Admin accounts");
//            }
//
//            if (targetUser.getRole() == User.Role.ADMIN) {
//                log.warn("ADMIN {} attempted to modify another ADMIN user {}",
//                        adminUsername, targetUser.getUsername());
//                throw new InsufficientPermissionException(
//                        "Admin cannot modify other Admin accounts");
//            }
//
//            log.debug("ADMIN {} has permission to modify user {}",
//                    adminUsername, targetUser.getUsername());
//            return;
//        }
//
//        // All other roles cannot perform admin operations
//        log.warn("User {} with role {} attempted admin operation on user {}",
//                adminUsername, admin.getRole(), targetUser.getUsername());
//        throw new InsufficientPermissionException(
//                "Insufficient permissions to perform this operation");
//    }
//
//    /**
//     * Validate user can be deactivated
//     * Prevents deactivation of SUPER_ADMIN and last active ADMIN
//     *
//     * @param user User to validate
//     * @throws InvalidUserOperationException if user cannot be deactivated
//     */
//    private void validateUserCanBeDeactivated(User user) {
//        // Prevent deactivation of SUPER_ADMIN
//        if (user.getRole() == User.Role.SUPER_ADMIN) {
//            log.warn("Attempted to deactivate SUPER_ADMIN user: {}", user.getUsername());
//            throw new InvalidUserOperationException(
//                    "Super Admin accounts cannot be deactivated");
//        }
//
//        // Prevent deactivation of last active ADMIN
//        if (user.getRole() == User.Role.ADMIN) {
//            long activeAdminCount = userRepository.findByRole(User.Role.ADMIN).stream()
//                    .filter(u -> u.getUserStatus() == User.UserStatus.ACTIVE && u.getIsActive())
//                    .count();
//
//            if (activeAdminCount <= 1) {
//                log.warn("Attempted to deactivate the last active ADMIN user: {}", user.getUsername());
//                throw new InvalidUserOperationException(
//                        "Cannot deactivate the last active Admin account");
//            }
//        }
//    }
//}