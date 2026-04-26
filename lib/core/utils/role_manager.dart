// ============================================================================
// ROLE MANAGER
// ============================================================================
// Complete role management for User and Admin roles
// ============================================================================

import 'package:flutter/material.dart';
import 'package:foodopia/core/utils/role_constant.dart';
import '../../features/auth/domain/entities/user_entity.dart';

/// User roles in the system
enum AppRole {
  user,   // Regular user
  admin,  // Administrator
}

/// Complete role management class
class RoleManager {
  // Singleton pattern
  static final RoleManager _instance = RoleManager._internal();
  factory RoleManager() => _instance;
  RoleManager._internal();

  // ========================================================================
  // ROLE CONVERSION
  // ========================================================================

  /// Convert string role from Firebase to enum
  AppRole fromString(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return AppRole.admin;
      case 'user':
      default:
        return AppRole.user;
    }
  }

  /// Convert enum to string for Firebase storage
  String roleToString(AppRole role) {
    return role.name;
  }

  // ========================================================================
  // ROLE CHECKS (Using String)
  // ========================================================================

  /// Check if user has admin privileges (by string)
  bool isAdmin(String? role) {
    return fromString(role) == AppRole.admin;
  }

  /// Check if user is regular user (by string)
  bool isUser(String? role) {
    return fromString(role) == AppRole.user;
  }

  // ========================================================================
  // ROLE CHECKS (Using UserEntity)
  // ========================================================================

  /// Check if user is admin (using UserEntity)
  bool checkIsAdmin(UserEntity? user) {
    return user?.isAdmin ?? false;
  }

  /// Check if user is regular user (using UserEntity)
  bool checkIsUser(UserEntity? user) {
    return user?.isUser ?? true;
  }

  String getDefaultRole() => RoleConstants.user;
  String getAdminRole() => RoleConstants.admin;

  /// Check if user is logged in
  bool isLoggedIn(UserEntity? user) {
    return user != null;
  }

  // ========================================================================
  // UI HELPERS
  // ========================================================================

  /// Get all available roles for dropdown menus
  List<Map<String, dynamic>> getAvailableRoles() {
    return [
      {'value': 'user', 'label': 'Regular User'},
      {'value': 'admin', 'label': 'Administrator'},
    ];
  }

  /// Get display name for role
  String getRoleDisplayName(String? role) {
    switch (fromString(role)) {
      case AppRole.admin:
        return 'Administrator';
      case AppRole.user:
        return 'Regular User';
    }
  }

  /// Get color for role badge
  Color getRoleColor(String? role) {
    switch (fromString(role)) {
      case AppRole.admin:
        return Colors.amber;
      case AppRole.user:
        return Colors.green;
    }
  }

  // ========================================================================
  // PERMISSIONS
  // ========================================================================

  /// Get permissions for a role
  RolePermissions getPermissions(String? role) {
    final userRole = fromString(role);
    switch (userRole) {
      case AppRole.admin:
        return RolePermissions(
          canCreate: true,
          canRead: true,
          canUpdate: true,
          canDelete: true,
          canManageUsers: true,
          canAccessAdminPanel: true,
        );
      case AppRole.user:
      default:
        return RolePermissions(
          canCreate: true,
          canRead: true,
          canUpdate: true,
          canDelete: false,
          canManageUsers: false,
          canAccessAdminPanel: false,
        );
    }
  }

  // ========================================================================
  // ROUTE PROTECTION (Former RoleGuard)
  // ========================================================================

  /// Require admin access - shows dialog if not admin
  Future<bool> requireAdmin(BuildContext context, UserEntity? user) async {
    if (checkIsAdmin(user)) {
      return true;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Access Denied'),
        content: const Text('Admin access required for this page.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    return false;
  }

  /// Require login - shows dialog if not logged in
  Future<bool> requireLogin(BuildContext context, UserEntity? user) async {
    if (isLoggedIn(user)) {
      return true;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('Please login to access this page.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Go to Login'),
          ),
        ],
      ),
    );

    return false;
  }
}

/// Permission set for each role
class RolePermissions {
  final bool canCreate;
  final bool canRead;
  final bool canUpdate;
  final bool canDelete;
  final bool canManageUsers;
  final bool canAccessAdminPanel;

  RolePermissions({
    required this.canCreate,
    required this.canRead,
    required this.canUpdate,
    required this.canDelete,
    required this.canManageUsers,
    required this.canAccessAdminPanel,
  });
}