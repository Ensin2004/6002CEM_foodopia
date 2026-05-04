// Defines the failures module.
// FAILURES
// ============================================================================
// Base failure class for error handling across the app
// ============================================================================

/// Base failure class for error handling
abstract class Failure {
  final String message;
  final String? code;

  /// Creates a failure instance.
  Failure({required this.message, this.code});
}

/// Generic failure for unexpected errors
class ServerFailure extends Failure {
  /// Creates a server failure instance.
  ServerFailure({required super.message, super.code});
}

/// Cache/local storage failure
class CacheFailure extends Failure {
  /// Creates a cache failure instance.
  CacheFailure({required super.message, super.code});
}

/// Network connection failure
class NetworkFailure extends Failure {
  /// Creates a network failure instance.
  NetworkFailure({required super.message, super.code});
}

/// Authentication failure
class AuthFailure extends Failure {
  /// Creates a auth failure instance.
  AuthFailure({required super.message, super.code});
}

// ============================================================================
// ADD THESE NEW FAILURE TYPES
// ============================================================================

/// Validation failure (input validation errors)
class ValidationFailure extends Failure {
  /// Creates a validation failure instance.
  ValidationFailure({required super.message, super.code});
}

/// Not found failure (when a resource is not found)
class NotFoundFailure extends Failure {
  /// Creates a not found failure instance.
  NotFoundFailure({required super.message, super.code});
}

/// Unauthorized failure (when user doesn't have permission)
class UnauthorizedFailure extends Failure {
  /// Creates a unauthorized failure instance.
  UnauthorizedFailure({required super.message, super.code});
}
