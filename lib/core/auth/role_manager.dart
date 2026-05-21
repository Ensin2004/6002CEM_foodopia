// Defines the role manager module.
// ROLE MANAGER
// ============================================================================
// Shared role logic for the whole app.
//
// This file belongs in core because roles are used by multiple features.
// Keep this file independent from feature classes such as UserEntity and from
// UI code such as dialogs or navigation. Features can depend on core, but core
// should not depend on features.
// ============================================================================

import 'package:foodopia/core/auth/role_constant.dart';

/// User roles supported by the app.
enum AppRole {
  user, // Regular user
  admin, // Administrator
}

/// Converts role values and exposes shared permission rules.
class RoleManager {
  // Singleton pattern: all callers use the same RoleManager instance.
  static final RoleManager _instance = RoleManager._internal();

  /// Handles the role manager operation.
  factory RoleManager() => _instance;

  RoleManager._internal();

  // ==========================================================================
  // ROLE CONVERSION
  // ==========================================================================

  /// Convert a role string from Firebase into the app enum.
  ///
  /// Unknown or null roles safely fall back to [AppRole.user].
  AppRole fromString(String? role) {
    switch (role?.toLowerCase()) {
      case RoleConstants.admin:
        return AppRole.admin;
      case RoleConstants.user:
      default:
        return AppRole.user;
    }
  }

  /// Convert an app role enum into a string for Firebase storage.
  String roleToString(AppRole role) {
    return role.name;
  }

  // ==========================================================================
  // ROLE CHECKS
  // ==========================================================================

  /// Check whether a role string represents an administrator.
  bool isAdmin(String? role) {
    /// Creates an instance from from string data.
    return fromString(role) == AppRole.admin;
  }

  /// Check whether a role string represents a regular user.
  bool isUser(String? role) {
    /// Creates an instance from from string data.
    return fromString(role) == AppRole.user;
  }

  /// Default role assigned to newly registered users.
  String getDefaultRole() => RoleConstants.user;

  /// Role value used for administrator accounts.
  String getAdminRole() => RoleConstants.admin;

  // ==========================================================================
  // DISPLAY HELPERS
  // ==========================================================================

  /// Options that can be shown in a role dropdown.
  List<Map<String, dynamic>> getAvailableRoles() {
    return [
      {'value': RoleConstants.user, 'label': 'Regular User'},
      {'value': RoleConstants.admin, 'label': 'Administrator'},
    ];
  }

  /// Human-readable role label for UI text.
  String getRoleDisplayName(String? role) {
    switch (fromString(role)) {
      case AppRole.admin:
        return 'Administrator';
      case AppRole.user:
        return 'Regular User';
    }
  }

  // ==========================================================================
  // PERMISSIONS
  // ==========================================================================

  /// Permission set assigned to a role.
  RolePermissions getPermissions(String? role) {
    switch (fromString(role)) {
      case AppRole.admin:
        /// Handles the role permissions operation.
        return RolePermissions(
          canCreate: true,
          canRead: true,
          canUpdate: true,
          canDelete: true,
          canManageUsers: true,
          canAccessAdminPanel: true,
        );
      case AppRole.user:
        /// Handles the role permissions operation.
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
}

/// Fine-grained permissions used by role-based screens and actions.
class RolePermissions {
  final bool canCreate;
  final bool canRead;
  final bool canUpdate;
  final bool canDelete;
  final bool canManageUsers;
  final bool canAccessAdminPanel;

  /// Creates a role permissions instance.
  RolePermissions({
    required this.canCreate,
    required this.canRead,
    required this.canUpdate,
    required this.canDelete,
    required this.canManageUsers,
    required this.canAccessAdminPanel,
  });
}
