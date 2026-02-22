package com.izak.demoBankManagement.repository;

import com.izak.demoBankManagement.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {

    /**
     * Find a user by username
     * @param username the username to search for
     * @return Optional containing the user if found
     */
    Optional<User> findByUsername(String username);

    /**
     * Find a user by email address
     * @param email the email to search for
     * @return Optional containing the user if found
     */
    Optional<User> findByEmail(String email);

    /**
     * Check if a username already exists
     * @param username the username to check
     * @return true if username exists, false otherwise
     */
    boolean existsByUsername(String username);

    /**
     * Check if an email already exists
     * @param email the email to check
     * @return true if email exists, false otherwise
     */
    boolean existsByEmail(String email);

    /**
     * Find all users with a specific role
     * @param role the role to search for
     * @return List of users with the specified role
     */
    List<User> findByRole(User.Role role);

    /**
     * Find all users with a specific user status
     * @param status the user status to search for
     * @return List of users with the specified status
     */
    List<User> findByUserStatus(User.UserStatus status);

    /**
     * Find all users belonging to a specific branch
     * @param branchId the branch ID to search for
     * @return List of users in the specified branch
     */
    List<User> findByBranchId(Long branchId);

    /**
     * Find all users with a specific role and user status
     * @param role the role to search for
     * @param status the user status to search for
     * @return List of users matching both criteria
     */
    List<User> findByRoleAndUserStatus(User.Role role, User.UserStatus status);

    /**
     * Find all users whose role is in the provided list
     * @param roles list of roles to search for
     * @return List of users with any of the specified roles
     */
    List<User> findByRoleIn(List<User.Role> roles);
}



//package com.izak.demoBankManagement.repository;
//
//import com.izak.demoBankManagement.entity.User;
//import org.springframework.data.jpa.repository.JpaRepository;
//import org.springframework.stereotype.Repository;
//
//import java.util.Optional;
//
//@Repository
//public interface UserRepository extends JpaRepository<User, Long> {
//    Optional<User> findByUsername(String username);
//    Optional<User> findByEmail(String email);
//    boolean existsByUsername(String username);
//    boolean existsByEmail(String email);
//}
