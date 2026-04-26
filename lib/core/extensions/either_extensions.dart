import 'package:dartz/dartz.dart';

// ============================================================================
// QUICK REFERENCE CARD
// ============================================================================
//
// | WHAT YOU WANT                    | CODE                                    |
// |-----------------------------------|-----------------------------------------|
// | Check if error                    | if (result.isLeft()) { ... }           |
// | Check if success                  | if (result.isRight()) { ... }          |
// | Get error (after checking)        | final error = result.left!;            |
// | Get success (after checking)      | final data = result.right!;            |
// | Handle both cases                 | result.fold(                           |
// |                                   |   (error) => handleError(error),       |
// |                                   |   (data) => handleSuccess(data),       |
// |                                   | );                                     |
// | Run code only for error           | result.ifLeft((e) => print(e));        |
// | Run code only for success         | result.ifRight((d) => print(d));       |
// | Create an error result            | return Left(Failure('error'));         |
// | Create a success result           | return Right(data);                    |
// ============================================================================

// ============================================================================
// WHAT IS EITHER? (Why not just use try-catch?)
// ============================================================================
//
// Either<L, R> is a container that holds either:
//   Left<L>  → ERROR (contains failure details)
//   Right<R> → SUCCESS (contains actual data)
//
// WHY USE EITHER INSTEAD OF TRY-CATCH?
// ============================================================================
//
// PROBLEM WITH TRY-CATCH (HIDDEN ERRORS):
// ┌─────────────────────────────────────────────────────────────────────────┐
// │ Future<User> login(String email, String password) async {              │
// │   try {                                                                │
// │     return await api.login(email, password);  // May throw!           │
// │   } catch (e) {                                                        │
// │     throw Exception('Login failed');                                   │
// │   }                                                                   │
// │ }                                                                     │
// │                                                                        │
// │ // CALLER HAS NO IDEA this function can throw!                        │
// │ final user = await login('a', 'b');  // ⚠️ Might crash! No warning!   │
// └─────────────────────────────────────────────────────────────────────────┘
//
// SOLUTION WITH EITHER (ERRORS ARE VISIBLE IN TYPE):
// ┌─────────────────────────────────────────────────────────────────────────┐
// │ Future<Either<Failure, User>> login(String email, String password) {  │
// │   try {                                                                │
// │     final user = await api.login(email, password);                    │
// │     return Right(user);  // ✅ Success is wrapped in Right            │
// │   } catch (e) {                                                        │
// │     return Left(Failure(e.toString()));  // ❌ Error is wrapped in Left│
// │   }                                                                   │
// │ }                                                                     │
// │                                                                        │
// │ // CALLER MUST handle BOTH cases! The type system ENFORCES it!        │
// │ final result = await login('a', 'b');                                 │
// │ if (result.isLeft()) {                                                │
// │   // Handle error                                                     │
// │ } else {                                                              │
// │   // Handle success                                                   │
// │ }                                                                     │
// └─────────────────────────────────────────────────────────────────────────┘
//
// KEY BENEFITS:
// 1. TYPE SAFETY - Function signature TELLS YOU it can fail
// 2. NO SURPRISES - No unexpected crashes from uncaught exceptions
// 3. FORCED HANDLING - You MUST check for errors before using data
// 4. SELF-DOCUMENTING - Anyone can see this function might fail
// ============================================================================

extension EitherExtension<L, R> on Either<L, R> {
  // ==========================================================================
  // CHECK WHAT TYPE IT IS
  // ==========================================================================

  /// Check if this is an ERROR (Left)
  bool isLeft() => this is Left<L, R>;

  /// Check if this is a SUCCESS (Right)
  bool isRight() => this is Right<L, R>;

  // ==========================================================================
  // GET THE VALUE (returns null if wrong type)
  // ==========================================================================

  /// Get error value (returns null if this is Right)
  L? get left {
    return fold((left) => left, (_) => null);
  }

  /// Get success value (returns null if this is Left)
  R? get right {
    return fold((_) => null, (right) => right);
  }

  // ==========================================================================
  // RUN CODE ONLY FOR SPECIFIC TYPE
  // ==========================================================================

  /// Run code only if this is an ERROR
  void ifLeft(void Function(L) action) {
    fold((left) => action(left), (_) => null);
  }

  /// Run code only if this is a SUCCESS
  void ifRight(void Function(R) action) {
    fold((_) => null, (right) => action(right));
  }

  // ==========================================================================
  // GET VALUE OR CRASH (use only when 100% sure!)
  // ==========================================================================

  L getLeftOrThrow() {
    return fold((left) => left, (_) => throw Exception('Not a Left'));
  }

  R getRightOrThrow() {
    return fold((_) => throw Exception('Not a Right'), (right) => right);
  }
}

// ============================================================================
// COMMON USAGE PATTERN
// ============================================================================
//
// final result = await someUseCase.execute();
//
// if (result.isLeft()) {
//   final error = result.left!;  // Use ! because we know it's Left
//   _errorMessage = error.message;
// } else {
//   final data = result.right!;  // Use ! because we know it's Right
//   _profile = data;
// }
// notifyListeners();
// ============================================================================