package com.izak.demoBankManagement.config;

import com.izak.demoBankManagement.entity.Branch;
import com.izak.demoBankManagement.entity.User;
import com.izak.demoBankManagement.repository.BranchRepository;
import com.izak.demoBankManagement.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

/**
 * DataInitializer - Creates default administrative users and test data for the bank management system
 *
 * This component runs on application startup and creates:
 * - 3 SUPER_ADMIN users (superadmin1, superadmin2, superadmin3)
 * - 3 ADMIN users (admin1, admin2, admin3)
 * - 2 Branches (Main Branch and Downtown Branch)
 * - 2 BRANCH_MANAGER users (one per branch)
 * - 1 LOAN_OFFICER for Main Branch
 * - 1 CARD_OFFICER for Downtown Branch
 * - 2 CUSTOMER users (no branch assignment)
 *
 * The initialization can be disabled by setting: app.init.default-users=false
 *
 * SECURITY NOTE: Default passwords should be changed immediately in production environments.
 */
@Component
@RequiredArgsConstructor
@Slf4j
@ConditionalOnProperty(name = "app.init.default-users", havingValue = "true", matchIfMissing = true)
public class DataInitializer implements CommandLineRunner {

    private final UserRepository userRepository;
    private final BranchRepository branchRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    @Transactional
    public void run(String... args) throws Exception {
        try {
            log.info("Initializing default users and test data...");

            // Check if any SUPER_ADMIN users exist
            long superAdminCount = userRepository.findByRole(User.Role.SUPER_ADMIN).size();

            if (superAdminCount > 0) {
                log.info("SUPER_ADMIN users already exist (count: {}). Skipping super admin initialization.", superAdminCount);
            } else {
                log.info("No SUPER_ADMIN users found. Creating default super admin accounts...");
                initializeSuperAdmins();
            }

            // Check if any ADMIN users exist
            long adminCount = userRepository.findByRole(User.Role.ADMIN).size();

            if (adminCount > 0) {
                log.info("ADMIN users already exist (count: {}). Skipping admin initialization.", adminCount);
            } else {
                log.info("No ADMIN users found. Creating default admin accounts...");
                initializeAdmins();
            }

            // Initialize branches and other users if database is empty
            if (userRepository.count() <= 7) { // Only super admins and admins exist
                log.info("Initializing branches and additional test users...");
                initializeBranches();
                initializeUsers();
            } else {
                log.info("Database already contains additional users. Skipping full initialization.");
            }

            log.info("Default users initialization completed successfully!");
            printCredentials();

        } catch (Exception e) {
            log.error("Error during data initialization: {}", e.getMessage(), e);
            // Don't rethrow - allow application to start even if initialization fails
        }
    }

    /**
     * Creates three SUPER_ADMIN accounts with predefined credentials
     *
     * SUPER_ADMIN users have the highest level of system access and can:
     * - Manage all other users including ADMINs
     * - Perform all administrative operations
     * - Access all branches and data
     */
    private void initializeSuperAdmins() {
        log.info("Creating SUPER_ADMIN accounts...");

        createSuperAdmin(
                "superadmin1",
                "SuperAdmin@123",
                "superadmin1@bank.internal"
        );

        createSuperAdmin(
                "superadmin2",
                "SuperAdmin@456",
                "superadmin2@bank.internal"
        );

        createSuperAdmin(
                "superadmin3",
                "SuperAdmin@789",
                "superadmin3@bank.internal"
        );

        log.info("Successfully created 3 SUPER_ADMIN accounts");
    }

    /**
     * Creates three ADMIN accounts with predefined credentials
     *
     * ADMIN users have elevated privileges and can:
     * - Manage users below ADMIN level
     * - Perform most administrative operations
     * - Cannot modify SUPER_ADMIN or other ADMIN accounts
     */
    private void initializeAdmins() {
        log.info("Creating ADMIN accounts...");

        createAdmin(
                "admin1",
                "Admin@123",
                "admin1@bank.internal"
        );

        createAdmin(
                "admin2",
                "Admin@456",
                "admin2@bank.internal"
        );

        createAdmin(
                "admin3",
                "Admin@789",
                "admin3@bank.internal"
        );

        createAdmin(
                "admin",
                "admin123",
                "admin@bank.com"
        );

        log.info("Successfully created 4 ADMIN accounts");
    }

    /**
     * Creates two branches: Main Branch and Downtown Branch
     */
    private void initializeBranches() {
        // Check if branches already exist
        if (branchRepository.count() > 0) {
            log.info("Branches already exist. Skipping branch initialization.");
            return;
        }

        log.info("Creating branches...");

        Branch mainBranch = new Branch();
        mainBranch.setBranchCode("MB001");
        mainBranch.setBranchName("Main Branch");
        mainBranch.setAddress("123 Main Street");
        mainBranch.setCity("Springfield");
        mainBranch.setState("IL");
        mainBranch.setZipCode("62701");
        mainBranch.setPhone("555-0100");
        mainBranch.setEmail("main@bank.com");
        mainBranch.setIfscCode("BANK0001001");
        mainBranch.setSwiftCode("BANKUS33");
        mainBranch.setStatus(Branch.BranchStatus.ACTIVE);
        mainBranch.setWorkingHours("9:00 AM - 5:00 PM");
        mainBranch.setIsMainBranch(true);
        branchRepository.save(mainBranch);
        log.info("Created Main Branch (Code: {})", mainBranch.getBranchCode());

        Branch downtownBranch = new Branch();
        downtownBranch.setBranchCode("DB001");
        downtownBranch.setBranchName("Downtown Branch");
        downtownBranch.setAddress("456 Downtown Avenue");
        downtownBranch.setCity("Springfield");
        downtownBranch.setState("IL");
        downtownBranch.setZipCode("62702");
        downtownBranch.setPhone("555-0200");
        downtownBranch.setEmail("downtown@bank.com");
        downtownBranch.setIfscCode("BANK0001002");
        downtownBranch.setSwiftCode("BANKUS34");
        downtownBranch.setStatus(Branch.BranchStatus.ACTIVE);
        downtownBranch.setWorkingHours("9:00 AM - 5:00 PM");
        downtownBranch.setIsMainBranch(false);
        branchRepository.save(downtownBranch);
        log.info("Created Downtown Branch (Code: {})", downtownBranch.getBranchCode());
    }

    /**
     * Creates all test users with proper role assignments and branch associations
     */
    private void initializeUsers() {
        Branch mainBranch = branchRepository.findByBranchCode("MB001")
                .orElseThrow(() -> new RuntimeException("Main Branch not found"));
        Branch downtownBranch = branchRepository.findByBranchCode("DB001")
                .orElseThrow(() -> new RuntimeException("Downtown Branch not found"));

        log.info("Creating branch-specific users...");

        User mainManager = createUser(
                "manager.main",
                "manager123",
                "manager.main@bank.com",
                User.Role.BRANCH_MANAGER,
                mainBranch
        );
        log.info("Created BRANCH_MANAGER for Main Branch: {}", mainManager.getUsername());

        User downtownManager = createUser(
                "manager.downtown",
                "manager123",
                "manager.downtown@bank.com",
                User.Role.BRANCH_MANAGER,
                downtownBranch
        );
        log.info("Created BRANCH_MANAGER for Downtown Branch: {}", downtownManager.getUsername());

        User loanOfficer = createUser(
                "loan.officer",
                "loan123",
                "loan.officer@bank.com",
                User.Role.LOAN_OFFICER,
                mainBranch
        );
        log.info("Created LOAN_OFFICER for Main Branch: {}", loanOfficer.getUsername());

        User cardOfficer = createUser(
                "card.officer",
                "card123",
                "card.officer@bank.com",
                User.Role.CARD_OFFICER,
                downtownBranch
        );
        log.info("Created CARD_OFFICER for Downtown Branch: {}", cardOfficer.getUsername());

        User customer1 = createUser(
                "customer1",
                "customer123",
                "customer1@email.com",
                User.Role.CUSTOMER,
                null
        );
        log.info("Created CUSTOMER user: {}", customer1.getUsername());

        User customer2 = createUser(
                "customer2",
                "customer123",
                "customer2@email.com",
                User.Role.CUSTOMER,
                null
        );
        log.info("Created CUSTOMER user: {}", customer2.getUsername());
    }

    /**
     * Helper method to create a SUPER_ADMIN user
     *
     * @param username Username for the super admin
     * @param password Plain text password (will be encoded)
     * @param email Email address
     */
    private void createSuperAdmin(String username, String password, String email) {
        try {
            // Check if user already exists
            if (userRepository.existsByUsername(username)) {
                log.warn("SUPER_ADMIN user '{}' already exists. Skipping creation.", username);
                return;
            }

            User superAdmin = new User();
            superAdmin.setUsername(username);
            superAdmin.setPassword(passwordEncoder.encode(password));
            superAdmin.setEmail(email);
            superAdmin.setRole(User.Role.SUPER_ADMIN);
            superAdmin.setUserStatus(User.UserStatus.ACTIVE);
            superAdmin.setIsActive(true);
            superAdmin.setMustChangePassword(false);
            superAdmin.setBranch(null); // SUPER_ADMIN has no branch assignment

            userRepository.save(superAdmin);

            log.info("Created SUPER_ADMIN: {}", username);

        } catch (Exception e) {
            log.error("Failed to create SUPER_ADMIN '{}': {}", username, e.getMessage());
        }
    }

    /**
     * Helper method to create an ADMIN user
     *
     * @param username Username for the admin
     * @param password Plain text password (will be encoded)
     * @param email Email address
     */
    private void createAdmin(String username, String password, String email) {
        try {
            // Check if user already exists
            if (userRepository.existsByUsername(username)) {
                log.warn("ADMIN user '{}' already exists. Skipping creation.", username);
                return;
            }

            User admin = new User();
            admin.setUsername(username);
            admin.setPassword(passwordEncoder.encode(password));
            admin.setEmail(email);
            admin.setRole(User.Role.ADMIN);
            admin.setUserStatus(User.UserStatus.ACTIVE);
            admin.setIsActive(true);
            admin.setMustChangePassword(false);
            admin.setBranch(null); // ADMIN has no branch assignment

            userRepository.save(admin);

            log.info("Created ADMIN: {}", username);

        } catch (Exception e) {
            log.error("Failed to create ADMIN '{}': {}", username, e.getMessage());
        }
    }

    /**
     * Helper method to create and save a user with encoded password
     *
     * @param username Username
     * @param password Plain text password (will be encoded)
     * @param email Email address
     * @param role User role
     * @param branch Branch assignment (null for roles that don't require branch)
     * @return Saved User entity
     */
    private User createUser(String username, String password, String email,
                            User.Role role, Branch branch) {
        User user = new User();
        user.setUsername(username);
        user.setPassword(passwordEncoder.encode(password));
        user.setEmail(email);
        user.setRole(role);
        user.setUserStatus(User.UserStatus.ACTIVE);
        user.setIsActive(true);
        user.setMustChangePassword(false);
        user.setBranch(branch);

        return userRepository.save(user);
    }

    /**
     * Prints all user credentials to the console for easy reference
     *
     * SECURITY WARNING: This method prints sensitive information to logs.
     * In production, consider removing or securing this output.
     */
    private void printCredentials() {
        log.info("\n" +
                "================================================================================\n" +
                "                    DEFAULT USER CREDENTIALS                                    \n" +
                "================================================================================\n" +
                "\n" +
                "SUPER ADMIN ACCOUNTS (Highest Privilege - No Branch Assignment):\n" +
                "\n" +
                "  Super Admin 1:\n" +
                "    Username: superadmin1\n" +
                "    Password: SuperAdmin@123\n" +
                "    Email: superadmin1@bank.internal\n" +
                "\n" +
                "  Super Admin 2:\n" +
                "    Username: superadmin2\n" +
                "    Password: SuperAdmin@456\n" +
                "    Email: superadmin2@bank.internal\n" +
                "\n" +
                "  Super Admin 3:\n" +
                "    Username: superadmin3\n" +
                "    Password: SuperAdmin@789\n" +
                "    Email: superadmin3@bank.internal\n" +
                "\n" +
                "--------------------------------------------------------------------------------\n" +
                "\n" +
                "ADMIN ACCOUNTS (No Branch Assignment):\n" +
                "\n" +
                "  Admin 1:\n" +
                "    Username: admin1\n" +
                "    Password: Admin@123\n" +
                "    Email: admin1@bank.internal\n" +
                "\n" +
                "  Admin 2:\n" +
                "    Username: admin2\n" +
                "    Password: Admin@456\n" +
                "    Email: admin2@bank.internal\n" +
                "\n" +
                "  Admin 3:\n" +
                "    Username: admin3\n" +
                "    Password: Admin@789\n" +
                "    Email: admin3@bank.internal\n" +
                "\n" +
                "--------------------------------------------------------------------------------\n" +
                "\n" +
                "BRANCH MANAGERS:\n" +
                "\n" +
                "  Main Branch Manager:\n" +
                "    Username: manager.main\n" +
                "    Password: manager123\n" +
                "    Email: manager.main@bank.com\n" +
                "    Branch: Main Branch (MB001)\n" +
                "\n" +
                "  Downtown Branch Manager:\n" +
                "    Username: manager.downtown\n" +
                "    Password: manager123\n" +
                "    Email: manager.downtown@bank.com\n" +
                "    Branch: Downtown Branch (DB001)\n" +
                "\n" +
                "--------------------------------------------------------------------------------\n" +
                "\n" +
                "LOAN OFFICER:\n" +
                "  Username: loan.officer\n" +
                "  Password: loan123\n" +
                "  Email: loan.officer@bank.com\n" +
                "  Branch: Main Branch (MB001)\n" +
                "\n" +
                "--------------------------------------------------------------------------------\n" +
                "\n" +
                "CARD OFFICER:\n" +
                "  Username: card.officer\n" +
                "  Password: card123\n" +
                "  Email: card.officer@bank.com\n" +
                "  Branch: Downtown Branch (DB001)\n" +
                "\n" +
                "--------------------------------------------------------------------------------\n" +
                "\n" +
                "CUSTOMERS (No Branch Assignment):\n" +
                "\n" +
                "  Customer 1:\n" +
                "    Username: customer1\n" +
                "    Password: customer123\n" +
                "    Email: customer1@email.com\n" +
                "\n" +
                "  Customer 2:\n" +
                "    Username: customer2\n" +
                "    Password: customer123\n" +
                "    Email: customer2@email.com\n" +
                "\n" +
                "================================================================================\n" +
                "  SECURITY NOTICE: Change default passwords immediately in production!         \n" +
                "================================================================================\n"
        );
    }
}





//package com.izak.demoBankManagement.config;
//
//import com.izak.demoBankManagement.entity.Branch;
//import com.izak.demoBankManagement.entity.User;
//import com.izak.demoBankManagement.repository.BranchRepository;
//import com.izak.demoBankManagement.repository.UserRepository;
//import lombok.RequiredArgsConstructor;
//import lombok.extern.slf4j.Slf4j;
//import org.springframework.boot.CommandLineRunner;
//import org.springframework.security.crypto.password.PasswordEncoder;
//import org.springframework.stereotype.Component;
//import org.springframework.transaction.annotation.Transactional;
//
///**
// * DataInitializer - Creates test data for the bank management system
// *
// * This component runs on application startup and creates:
// * - 1 ADMIN user (no branch assignment)
// * - 2 Branches (Main Branch and Downtown Branch)
// * - 2 BRANCH_MANAGER users (one per branch)
// * - 1 LOAN_OFFICER for Main Branch
// * - 1 CARD_OFFICER for Downtown Branch
// * - 2 CUSTOMER users (no branch assignment)
// */
//@Component
//@RequiredArgsConstructor
//@Slf4j
//public class DataInitializer implements CommandLineRunner {
//
//    private final UserRepository userRepository;
//    private final BranchRepository branchRepository;
//    private final PasswordEncoder passwordEncoder;
//
//    @Override
//    @Transactional
//    public void run(String... args) throws Exception {
//        // Only initialize if database is empty
//        if (userRepository.count() == 0) {
//            log.info("Initializing test data...");
//
//            initializeBranches();
//            initializeUsers();
//
//            log.info("Test data initialization completed successfully!");
//            printCredentials();
//        } else {
//            log.info("Database already contains data. Skipping initialization.");
//        }
//    }
//
//    /**
//     * Creates two branches: Main Branch and Downtown Branch
//     */
//    private void initializeBranches() {
//        // Main Branch
//        Branch mainBranch = new Branch();
//        mainBranch.setBranchCode("MB001");
//        mainBranch.setBranchName("Main Branch");
//        mainBranch.setAddress("123 Main Street");
//        mainBranch.setCity("Springfield");
//        mainBranch.setState("IL");
//        mainBranch.setZipCode("62701");
//        mainBranch.setPhone("555-0100");
//        mainBranch.setEmail("main@bank.com");
//        mainBranch.setIfscCode("BANK0001001");
//        mainBranch.setSwiftCode("BANKUS33");
//        mainBranch.setStatus(Branch.BranchStatus.ACTIVE);
//        mainBranch.setWorkingHours("9:00 AM - 5:00 PM");
//        mainBranch.setIsMainBranch(true);
//        branchRepository.save(mainBranch);
//        log.info("Created Main Branch (ID: {})", mainBranch.getId());
//
//        // Downtown Branch
//        Branch downtownBranch = new Branch();
//        downtownBranch.setBranchCode("DB001");
//        downtownBranch.setBranchName("Downtown Branch");
//        downtownBranch.setAddress("456 Downtown Avenue");
//        downtownBranch.setCity("Springfield");
//        downtownBranch.setState("IL");
//        downtownBranch.setZipCode("62702");
//        downtownBranch.setPhone("555-0200");
//        downtownBranch.setEmail("downtown@bank.com");
//        downtownBranch.setIfscCode("BANK0001002");
//        downtownBranch.setSwiftCode("BANKUS34");
//        downtownBranch.setStatus(Branch.BranchStatus.ACTIVE);
//        downtownBranch.setWorkingHours("9:00 AM - 5:00 PM");
//        downtownBranch.setIsMainBranch(false);
//        branchRepository.save(downtownBranch);
//        log.info("Created Downtown Branch (ID: {})", downtownBranch.getId());
//    }
//
//    /**
//     * Creates all test users with proper role assignments and branch associations
//     */
//    private void initializeUsers() {
//        Branch mainBranch = branchRepository.findByBranchCode("MB001")
//                .orElseThrow(() -> new RuntimeException("Main Branch not found"));
//        Branch downtownBranch = branchRepository.findByBranchCode("DB001")
//                .orElseThrow(() -> new RuntimeException("Downtown Branch not found"));
//
//        // 1. ADMIN User (no branch)
//        // Username: admin | Password: admin123
//        User admin = createUser(
//                "admin",
//                "admin123",
//                "admin@bank.com",
//                User.Role.ADMIN,
//                null
//        );
//        log.info("Created ADMIN user: {}", admin.getUsername());
//
//        // 2. BRANCH_MANAGER for Main Branch
//        // Username: manager.main | Password: manager123
//        User mainManager = createUser(
//                "manager.main",
//                "manager123",
//                "manager.main@bank.com",
//                User.Role.BRANCH_MANAGER,
//                mainBranch
//        );
//        log.info("Created BRANCH_MANAGER for Main Branch: {}", mainManager.getUsername());
//
//        // 3. BRANCH_MANAGER for Downtown Branch
//        // Username: manager.downtown | Password: manager123
//        User downtownManager = createUser(
//                "manager.downtown",
//                "manager123",
//                "manager.downtown@bank.com",
//                User.Role.BRANCH_MANAGER,
//                downtownBranch
//        );
//        log.info("Created BRANCH_MANAGER for Downtown Branch: {}", downtownManager.getUsername());
//
//        // 4. LOAN_OFFICER for Main Branch
//        // Username: loan.officer | Password: loan123
//        User loanOfficer = createUser(
//                "loan.officer",
//                "loan123",
//                "loan.officer@bank.com",
//                User.Role.LOAN_OFFICER,
//                mainBranch
//        );
//        log.info("Created LOAN_OFFICER for Main Branch: {}", loanOfficer.getUsername());
//
//        // 5. CARD_OFFICER for Downtown Branch
//        // Username: card.officer | Password: card123
//        User cardOfficer = createUser(
//                "card.officer",
//                "card123",
//                "card.officer@bank.com",
//                User.Role.CARD_OFFICER,
//                downtownBranch
//        );
//        log.info("Created CARD_OFFICER for Downtown Branch: {}", cardOfficer.getUsername());
//
//        // 6. CUSTOMER User 1 (no branch)
//        // Username: customer1 | Password: customer123
//        User customer1 = createUser(
//                "customer1",
//                "customer123",
//                "customer1@email.com",
//                User.Role.CUSTOMER,
//                null
//        );
//        log.info("Created CUSTOMER user: {}", customer1.getUsername());
//
//        // 7. CUSTOMER User 2 (no branch)
//        // Username: customer2 | Password: customer123
//        User customer2 = createUser(
//                "customer2",
//                "customer123",
//                "customer2@email.com",
//                User.Role.CUSTOMER,
//                null
//        );
//        log.info("Created CUSTOMER user: {}", customer2.getUsername());
//    }
//
//    /**
//     * Helper method to create and save a user with encoded password
//     */
//    private User createUser(String username, String password, String email,
//                            User.Role role, Branch branch) {
//        User user = new User();
//        user.setUsername(username);
//        user.setPassword(passwordEncoder.encode(password));
//        user.setEmail(email);
//        user.setRole(role);
//        user.setIsActive(true);
//        user.setBranch(branch);
//        return userRepository.save(user);
//    }
//
//    /**
//     * Prints all user credentials to the console for easy reference
//     */
//    private void printCredentials() {
//        log.info("\n" +
//                "================================================================================\n" +
//                "                        TEST USER CREDENTIALS                                   \n" +
//                "================================================================================\n" +
//                "\n" +
//                "ADMIN (No Branch Assignment):\n" +
//                "  Username: admin\n" +
//                "  Password: admin123\n" +
//                "  Email: admin@bank.com\n" +
//                "\n" +
//                "--------------------------------------------------------------------------------\n" +
//                "\n" +
//                "BRANCH MANAGERS:\n" +
//                "\n" +
//                "  Main Branch Manager:\n" +
//                "    Username: manager.main\n" +
//                "    Password: manager123\n" +
//                "    Email: manager.main@bank.com\n" +
//                "    Branch: Main Branch (MB001)\n" +
//                "\n" +
//                "  Downtown Branch Manager:\n" +
//                "    Username: manager.downtown\n" +
//                "    Password: manager123\n" +
//                "    Email: manager.downtown@bank.com\n" +
//                "    Branch: Downtown Branch (DB001)\n" +
//                "\n" +
//                "--------------------------------------------------------------------------------\n" +
//                "\n" +
//                "LOAN OFFICER:\n" +
//                "  Username: loan.officer\n" +
//                "  Password: loan123\n" +
//                "  Email: loan.officer@bank.com\n" +
//                "  Branch: Main Branch (MB001)\n" +
//                "\n" +
//                "--------------------------------------------------------------------------------\n" +
//                "\n" +
//                "CARD OFFICER:\n" +
//                "  Username: card.officer\n" +
//                "  Password: card123\n" +
//                "  Email: card.officer@bank.com\n" +
//                "  Branch: Downtown Branch (DB001)\n" +
//                "\n" +
//                "--------------------------------------------------------------------------------\n" +
//                "\n" +
//                "CUSTOMERS (No Branch Assignment):\n" +
//                "\n" +
//                "  Customer 1:\n" +
//                "    Username: customer1\n" +
//                "    Password: customer123\n" +
//                "    Email: customer1@email.com\n" +
//                "\n" +
//                "  Customer 2:\n" +
//                "    Username: customer2\n" +
//                "    Password: customer123\n" +
//                "    Email: customer2@email.com\n" +
//                "\n" +
//                "================================================================================\n"
//        );
//    }
//}










//package com.izak.demoBankManagement.config;
//
//import com.izak.demoBankManagement.entity.User;
//import com.izak.demoBankManagement.repository.UserRepository;
//import lombok.RequiredArgsConstructor;
//import lombok.extern.slf4j.Slf4j;
//import org.springframework.boot.CommandLineRunner;
//import org.springframework.security.crypto.password.PasswordEncoder;
//import org.springframework.stereotype.Component;
//
//@Component
//@RequiredArgsConstructor
//@Slf4j
//public class DataInitializer implements CommandLineRunner {
//
//    private final UserRepository userRepository;
//    private final PasswordEncoder passwordEncoder;
//
//    @Override
//    public void run(String... args) {
//        // Create Admin user if none exists
//        if (!userRepository.existsByUsername("admin")) {
//            User admin = new User();
//            admin.setUsername("admin");
//            // Encoded once here, directly into the repository
//            admin.setPassword(passwordEncoder.encode("admin123"));
//            admin.setEmail("admin@demobank.com");
//            admin.setRole(User.Role.ADMIN);
//            admin.setIsActive(true);
//
//            userRepository.save(admin);
//            log.info("Successfully created default system admin: 'admin'");
//        }
//    }
//}