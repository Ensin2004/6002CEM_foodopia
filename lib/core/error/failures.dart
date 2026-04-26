// ============================================================================
// FAILURES
// ============================================================================
// Base failure class for error handling across the app
// ============================================================================

/// Base failure class for error handling
abstract class Failure {
  final String message;
  final String? code;

  Failure({required this.message, this.code});
}

/// Generic failure for unexpected errors
class ServerFailure extends Failure {
  ServerFailure({required super.message, super.code});
}

/// Cache/local storage failure
class CacheFailure extends Failure {
  CacheFailure({required super.message, super.code});
}

/// Network connection failure
class NetworkFailure extends Failure {
  NetworkFailure({required super.message, super.code});
}

/// Authentication failure
class AuthFailure extends Failure {
  AuthFailure({required super.message, super.code});
}

// ============================================================================
// ADD THESE NEW FAILURE TYPES
// ============================================================================

/// Validation failure (input validation errors)
class ValidationFailure extends Failure {
  ValidationFailure({required super.message, super.code});
}

/// Not found failure (when a resource is not found)
class NotFoundFailure extends Failure {
  NotFoundFailure({required super.message, super.code});
}

/// Unauthorized failure (when user doesn't have permission)
class UnauthorizedFailure extends Failure {
  UnauthorizedFailure({required super.message, super.code});
}