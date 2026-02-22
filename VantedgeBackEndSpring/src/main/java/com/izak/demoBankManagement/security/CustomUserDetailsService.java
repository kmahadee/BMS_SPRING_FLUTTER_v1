package com.izak.demoBankManagement.security;

import com.izak.demoBankManagement.entity.User;
import com.izak.demoBankManagement.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.Collection;
import java.util.Collections;


@Service
@RequiredArgsConstructor
@Slf4j
public class CustomUserDetailsService implements UserDetailsService {

    private final UserRepository userRepository;

    /**
     * Load user details by username for authentication.
     *
     * This method:
     * 1. Retrieves user from database
     * 2. Validates user status (only ACTIVE users can authenticate)
     * 3. Builds Spring Security UserDetails object
     *
     * @param username the username to authenticate
     * @return UserDetails object for Spring Security
     * @throws UsernameNotFoundException if user not found or not active
     */
    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        // Load user from database
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + username));

        // Validate user status - only ACTIVE users can authenticate
        // Allow null userStatus for backward compatibility with existing users
        if (user.getUserStatus() != null && user.getUserStatus() != User.UserStatus.ACTIVE) {
            log.warn("Authentication attempt by non-active user: {} (status: {})",
                    username, user.getUserStatus());
            throw new UsernameNotFoundException("User account is not active");
        }

        // Build and return Spring Security UserDetails object
        return new org.springframework.security.core.userdetails.User(
                user.getUsername(),
                user.getPassword(),
                user.getIsActive(),
                true,
                true,
                true,
                getAuthorities(user)
        );
    }

    /**
     * Convert user role to Spring Security authorities.
     *
     * @param user the user entity
     * @return collection of granted authorities
     */
    private Collection<? extends GrantedAuthority> getAuthorities(User user) {
        return Collections.singletonList(
                new SimpleGrantedAuthority("ROLE_" + user.getRole().name())
        );
    }
}






//package com.izak.demoBankManagement.security;
//
//import com.izak.demoBankManagement.entity.User;
//import com.izak.demoBankManagement.repository.UserRepository;
//import lombok.RequiredArgsConstructor;
//import org.springframework.security.core.GrantedAuthority;
//import org.springframework.security.core.authority.SimpleGrantedAuthority;
//import org.springframework.security.core.userdetails.UserDetails;
//import org.springframework.security.core.userdetails.UserDetailsService;
//import org.springframework.security.core.userdetails.UsernameNotFoundException;
//import org.springframework.stereotype.Service;
//
//import java.util.Collection;
//import java.util.Collections;
//
//@Service
//@RequiredArgsConstructor
//public class CustomUserDetailsService implements UserDetailsService {
//
//    private final UserRepository userRepository;
//
//    @Override
//    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
//        User user = userRepository.findByUsername(username)
//                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + username));
//
//        return new org.springframework.security.core.userdetails.User(
//                user.getUsername(),
//                user.getPassword(),
//                user.getIsActive(),
//                true,
//                true,
//                true,
//                getAuthorities(user)
//        );
//    }
//
//    private Collection<? extends GrantedAuthority> getAuthorities(User user) {
//        return Collections.singletonList(
//                new SimpleGrantedAuthority("ROLE_" + user.getRole().name())
//        );
//    }
//}