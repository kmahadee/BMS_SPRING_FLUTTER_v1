    package com.izak.demoBankManagement.entity;

    import jakarta.persistence.*;
    import lombok.AllArgsConstructor;
    import lombok.Data;
    import lombok.NoArgsConstructor;
    import org.hibernate.annotations.CreationTimestamp;
    import org.hibernate.annotations.UpdateTimestamp;

    import java.time.LocalDateTime;

    @Entity
    @Table(name = "users")
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public class User {

        @Id
        @GeneratedValue(strategy = GenerationType.IDENTITY)
        private Long id;

        @Column(unique = true, nullable = false, length = 50)
        private String username;

        @Column(nullable = false)
        private String password;

        @Column(unique = true, nullable = false, length = 100)
        private String email;

        @Enumerated(EnumType.STRING)
        @Column(nullable = false, length = 20)
        private Role role;

        @Column(nullable = false)
        private Boolean isActive = true;

        // Branch association for employees (nullable for backward compatibility)
        @ManyToOne(fetch = FetchType.LAZY)
        @JoinColumn(name = "branch_id")
        private Branch branch;

        // User status and approval fields
        @Enumerated(EnumType.STRING)
        @Column(nullable = true, length = 20)
        private UserStatus userStatus;

        @Column(nullable = true)
        private Boolean mustChangePassword;

        @Column(nullable = true, length = 500)
        private String approvalReason;

        @Column(nullable = true, length = 50)
        private String approvedBy;

        @Column(nullable = true)
        private LocalDateTime approvedDate;

        @CreationTimestamp
        @Column(nullable = false, updatable = false)
        private LocalDateTime createdDate;

        @UpdateTimestamp
        private LocalDateTime lastModified;


        // Enum for User Roles
        public enum Role {
            SUPER_ADMIN,
            ADMIN,
            CUSTOMER,
            EMPLOYEE,           // Keep for backward compatibility with SecurityConfig
            BRANCH_MANAGER,
            LOAN_OFFICER,
            CARD_OFFICER
        }

        // Enum for User Status
        public enum UserStatus {
            PENDING,
            ACTIVE,
            INACTIVE
        }
    }















    //package com.izak.demoBankManagement.entity;
    //
    //import jakarta.persistence.*;
    //import lombok.AllArgsConstructor;
    //import lombok.Data;
    //import lombok.NoArgsConstructor;
    //import org.hibernate.annotations.CreationTimestamp;
    //import org.hibernate.annotations.UpdateTimestamp;
    //
    //import java.time.LocalDateTime;
    //
    //@Entity
    //@Table(name = "users")
    //@Data
    //@NoArgsConstructor
    //@AllArgsConstructor
    //public class User {
    //
    //    @Id
    //    @GeneratedValue(strategy = GenerationType.IDENTITY)
    //    private Long id;
    //
    //    @Column(unique = true, nullable = false, length = 50)
    //    private String username;
    //
    //    @Column(nullable = false)
    //    private String password;
    //
    //    @Column(unique = true, nullable = false, length = 100)
    //    private String email;
    //
    //    @Enumerated(EnumType.STRING)
    //    @Column(nullable = false, length = 20)
    //    private Role role;
    //
    //    @Column(nullable = false)
    //    private Boolean isActive = true;
    //
    //    // Branch association for employees (nullable for backward compatibility)
    //    @ManyToOne(fetch = FetchType.LAZY)
    //    @JoinColumn(name = "branch_id")
    //    private Branch branch;
    //
    //    @CreationTimestamp
    //    @Column(nullable = false, updatable = false)
    //    private LocalDateTime createdDate;
    //
    //    @UpdateTimestamp
    //    private LocalDateTime lastModified;
    //
    //
    //
    //
    //
    //
    //    //====================================================================
    //
    //
    //
    //
    //
    //    // User status and approval fields
    //    @Enumerated(EnumType.STRING)
    //    @Column(nullable = true, length = 20)
    //    private UserStatus userStatus;
    //
    //    @Column(nullable = true)
    //    private Boolean mustChangePassword;
    //
    //    @Column(nullable = true, length = 500)
    //    private String approvalReason;
    //
    //    @Column(nullable = true, length = 50)
    //    private String approvedBy;
    //
    //    @Column(nullable = true)
    //    private LocalDateTime approvedDate;
    //
    //
    //
    //
    //
    //    //====================================================================
    //
    //
    //
    //
    //
    //    // Enum for User Roles
    //    public enum Role {
    //        SUPER_ADMIN,
    //        ADMIN,
    //        CUSTOMER,
    //        EMPLOYEE,           // Keep for backward compatibility with SecurityConfig
    //        BRANCH_MANAGER,
    //        LOAN_OFFICER,
    //        CARD_OFFICER
    //    }
    //
    //
    //    public enum UserStatus {
    //        PENDING,
    //        ACTIVE,
    //        INACTIVE
    //    }
    //
    //}
    //
    //
