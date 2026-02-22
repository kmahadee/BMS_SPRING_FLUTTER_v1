import 'package:flutter/material.dart';

/// Model representing a quick action button in the dashboard
/// 
/// Quick actions provide one-tap access to common features and functions.
class QuickActionModel {
  /// Type of action (e.g., 'transfer', 'pay_bill', 'view_statement')
  final String actionType;
  
  /// Display label for the action
  final String label;
  
  /// Icon to display (icon code point)
  final IconData icon;
  
  /// Route to navigate to when action is tapped
  final String route;
  
  /// Optional subtitle/description
  final String? description;
  
  /// Whether this action requires authentication
  final bool requiresAuth;
  
  /// Background color for the action button (hex string)
  final String? backgroundColor;
  
  /// Icon color (hex string)
  final String? iconColor;
  
  /// Whether this action is enabled
  final bool isEnabled;
  
  /// Badge text to display (e.g., "New", "3")
  final String? badgeText;

  const QuickActionModel({
    required this.actionType,
    required this.label,
    required this.icon,
    required this.route,
    this.description,
    this.requiresAuth = true,
    this.backgroundColor,
    this.iconColor,
    this.isEnabled = true,
    this.badgeText,
  });

  /// Create QuickActionModel from JSON map
  factory QuickActionModel.fromJson(Map<String, dynamic> json) {
    return QuickActionModel(
      actionType: json['actionType'] as String,
      label: json['label'] as String,
      icon: IconData(
        json['iconCodePoint'] as int,
        fontFamily: json['iconFontFamily'] as String?,
      ),
      route: json['route'] as String,
      description: json['description'] as String?,
      requiresAuth: json['requiresAuth'] as bool? ?? true,
      backgroundColor: json['backgroundColor'] as String?,
      iconColor: json['iconColor'] as String?,
      isEnabled: json['isEnabled'] as bool? ?? true,
      badgeText: json['badgeText'] as String?,
    );
  }

  /// Convert QuickActionModel to JSON map
  Map<String, dynamic> toJson() {
    return {
      'actionType': actionType,
      'label': label,
      'iconCodePoint': icon.codePoint,
      if (icon.fontFamily != null) 'iconFontFamily': icon.fontFamily,
      'route': route,
      if (description != null) 'description': description,
      'requiresAuth': requiresAuth,
      if (backgroundColor != null) 'backgroundColor': backgroundColor,
      if (iconColor != null) 'iconColor': iconColor,
      'isEnabled': isEnabled,
      if (badgeText != null) 'badgeText': badgeText,
    };
  }

  /// Create a copy with modified fields
  QuickActionModel copyWith({
    String? actionType,
    String? label,
    IconData? icon,
    String? route,
    String? description,
    bool? requiresAuth,
    String? backgroundColor,
    String? iconColor,
    bool? isEnabled,
    String? badgeText,
  }) {
    return QuickActionModel(
      actionType: actionType ?? this.actionType,
      label: label ?? this.label,
      icon: icon ?? this.icon,
      route: route ?? this.route,
      description: description ?? this.description,
      requiresAuth: requiresAuth ?? this.requiresAuth,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      iconColor: iconColor ?? this.iconColor,
      isEnabled: isEnabled ?? this.isEnabled,
      badgeText: badgeText ?? this.badgeText,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuickActionModel && other.actionType == actionType;
  }

  @override
  int get hashCode => actionType.hashCode;

  @override
  String toString() {
    return 'QuickActionModel(type: $actionType, label: $label, route: $route)';
  }
}

/// Predefined quick actions for different user roles
class QuickActions {
  QuickActions._();

  /// Customer quick actions
  static List<QuickActionModel> get customerActions => [
        QuickActionModel(
          actionType: 'transfer',
          label: 'Transfer Money',
          icon: Icons.send,
          route: '/transfer',
          description: 'Transfer funds to another account',
          backgroundColor: '#4CAF50',
          iconColor: '#FFFFFF',
        ),
        QuickActionModel(
          actionType: 'pay_bill',
          label: 'Pay Bill',
          icon: Icons.receipt_long,
          route: '/pay-bill',
          description: 'Pay utility bills and invoices',
          backgroundColor: '#2196F3',
          iconColor: '#FFFFFF',
        ),
        QuickActionModel(
          actionType: 'view_statement',
          label: 'Statement',
          icon: Icons.description,
          route: '/statement',
          description: 'View account statement',
          backgroundColor: '#FF9800',
          iconColor: '#FFFFFF',
        ),
        QuickActionModel(
          actionType: 'apply_loan',
          label: 'Apply Loan',
          icon: Icons.account_balance,
          route: '/loan/apply',
          description: 'Apply for a new loan',
          backgroundColor: '#9C27B0',
          iconColor: '#FFFFFF',
        ),
      ];

  /// Branch manager quick actions
  static List<QuickActionModel> get branchManagerActions => [
        QuickActionModel(
          actionType: 'approvals',
          label: 'Approvals',
          icon: Icons.check_circle,
          route: '/approvals',
          description: 'Pending approvals',
          backgroundColor: '#FF5722',
          iconColor: '#FFFFFF',
        ),
        QuickActionModel(
          actionType: 'new_account',
          label: 'New Account',
          icon: Icons.person_add,
          route: '/account/create',
          description: 'Create new account',
          backgroundColor: '#4CAF50',
          iconColor: '#FFFFFF',
        ),
        QuickActionModel(
          actionType: 'reports',
          label: 'Reports',
          icon: Icons.assessment,
          route: '/reports',
          description: 'View branch reports',
          backgroundColor: '#2196F3',
          iconColor: '#FFFFFF',
        ),
        QuickActionModel(
          actionType: 'staff',
          label: 'Staff',
          icon: Icons.groups,
          route: '/staff',
          description: 'Manage staff',
          backgroundColor: '#9C27B0',
          iconColor: '#FFFFFF',
        ),
      ];

  /// Loan officer quick actions
  static List<QuickActionModel> get loanOfficerActions => [
        QuickActionModel(
          actionType: 'loan_applications',
          label: 'Applications',
          icon: Icons.assignment,
          route: '/loan/applications',
          description: 'View loan applications',
          backgroundColor: '#2196F3',
          iconColor: '#FFFFFF',
        ),
        QuickActionModel(
          actionType: 'loan_approvals',
          label: 'Approvals',
          icon: Icons.approval,
          route: '/loan/approvals',
          description: 'Approve loan applications',
          backgroundColor: '#4CAF50',
          iconColor: '#FFFFFF',
        ),
        QuickActionModel(
          actionType: 'disbursements',
          label: 'Disbursements',
          icon: Icons.payments,
          route: '/loan/disbursements',
          description: 'Process disbursements',
          backgroundColor: '#FF9800',
          iconColor: '#FFFFFF',
        ),
      ];

  /// Card officer quick actions
  static List<QuickActionModel> get cardOfficerActions => [
        QuickActionModel(
          actionType: 'card_applications',
          label: 'Applications',
          icon: Icons.credit_card,
          route: '/card/applications',
          description: 'View card applications',
          backgroundColor: '#2196F3',
          iconColor: '#FFFFFF',
        ),
        QuickActionModel(
          actionType: 'card_management',
          label: 'Card Management',
          icon: Icons.manage_accounts,
          route: '/card/manage',
          description: 'Manage issued cards',
          backgroundColor: '#4CAF50',
          iconColor: '#FFFFFF',
        ),
      ];

  /// Admin quick actions
  static List<QuickActionModel> get adminActions => [
        QuickActionModel(
          actionType: 'user_management',
          label: 'Users',
          icon: Icons.people,
          route: '/admin/users',
          description: 'Manage users',
          backgroundColor: '#2196F3',
          iconColor: '#FFFFFF',
        ),
        QuickActionModel(
          actionType: 'branch_management',
          label: 'Branches',
          icon: Icons.business,
          route: '/admin/branches',
          description: 'Manage branches',
          backgroundColor: '#4CAF50',
          iconColor: '#FFFFFF',
        ),
        QuickActionModel(
          actionType: 'system_settings',
          label: 'Settings',
          icon: Icons.settings,
          route: '/admin/settings',
          description: 'System settings',
          backgroundColor: '#9C27B0',
          iconColor: '#FFFFFF',
        ),
        QuickActionModel(
          actionType: 'audit_logs',
          label: 'Audit Logs',
          icon: Icons.history,
          route: '/admin/audit',
          description: 'View audit logs',
          backgroundColor: '#FF5722',
          iconColor: '#FFFFFF',
        ),
      ];
}