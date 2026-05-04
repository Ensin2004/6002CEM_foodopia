import 'package:dartz/dartz.dart';

// ============================================================================
// EITHER EXTENSIONS
// ============================================================================
// Either<L, R> represents one of two possible results:
//   Left<L>  = failure / error
//   Right<R> = success / data
//
// Why use Either?
// - The return type clearly shows that an operation can fail.
// - Callers are encouraged to handle both success and failure.
// - Viewmodels can avoid relying on thrown exceptions for expected errors.
//
// Why use Either instead of try-catch?
// - try-catch hides possible failures unless the caller reads the function body.
// - Either makes failure part of the function signature.
// - Expected errors, such as validation or not found, can be returned as values.
// - Unexpected errors can still be caught and converted into a Failure.
//
// Common pattern:
//   final result = await someUseCase.execute();
//
//   result.fold(
//     (failure) => handleError(failure),
//     (data) => handleSuccess(data),
//   );
//
// These extension methods make simple checks shorter when a viewmodel needs to
// inspect only one side of the result.
//
// Quick summary:
// | Need                         | Use                                 |
// |------------------------------|--------------------------------------|
// | Check if error               | result.isLeft()                      |
// | Check if success             | result.isRight()                     |
// | Get error after checking     | result.left                          |
// | Get data after checking      | result.right                         |
// | Handle both outcomes         | result.fold(onFailure, onSuccess)    |
// | Run code only for error      | result.ifLeft((failure) { ... })     |
// | Run code only for success    | result.ifRight((data) { ... })       |
// ============================================================================

extension EitherExtension<L, R> on Either<L, R> {
  // ==========================================================================
  // TYPE CHECKS
  // ==========================================================================

  /// Returns true when this Either contains an error/left value.
  bool isLeft() => this is Left<L, R>;

  /// Returns true when this Either contains a success/right value.
  bool isRight() => this is Right<L, R>;

  // ==========================================================================
  // SAFE VALUE ACCESS
  // ==========================================================================

  /// Returns the left value, or null when this Either is a Right.
  L? get left {
    return fold((left) => left, (_) => null);
  }

  /// Returns the right value, or null when this Either is a Left.
  R? get right {
    return fold((_) => null, (right) => right);
  }

  // ==========================================================================
  // CONDITIONAL CALLBACKS
  // ==========================================================================

  /// Runs [action] only when this Either is a Left.
  void ifLeft(void Function(L left) action) {
    /// Creates a fold instance.
    fold(action, (_) => null);
  }

  /// Runs [action] only when this Either is a Right.
  void ifRight(void Function(R right) action) {
    /// Creates a fold instance.
    fold((_) => null, action);
  }

  // ==========================================================================
  // STRICT VALUE ACCESS
  // ==========================================================================

  /// Returns the left value or throws if this Either is a Right.
  ///
  /// Use only after confirming the result is a Left.
  L getLeftOrThrow() {
    return fold((left) => left, (_) => throw StateError('Either is not Left'));
  }

  /// Returns the right value or throws if this Either is a Left.
  ///
  /// Use only after confirming the result is a Right.
  R getRightOrThrow() {
    return fold((_) => throw StateError('Either is not Right'), (right) => right);
  }
}
