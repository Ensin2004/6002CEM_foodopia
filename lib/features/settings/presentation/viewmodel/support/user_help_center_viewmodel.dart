import 'dart:io';

import 'package:flutter/foundation.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/extensions/either_extensions.dart';
import '../../../domain/entities/help_center_issue.dart';
import '../../../domain/usecases/support/help_center/get_user_issues_usecase.dart';
import '../../../domain/usecases/support/help_center/submit_issue_usecase.dart';

/// Defines behavior for user help center view model.
class UserHelpCenterViewModel extends ChangeNotifier {
  final GetUserIssuesUseCase _getUserIssuesUseCase;
  final SubmitIssueUseCase _submitIssueUseCase;
  final String _uid;

  // State
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  List<HelpCenterIssue> _issues = [];
  String _filterStatus = 'All';
  bool _sortLatestFirst = true;

  /// Creates a user help center view model instance.
  UserHelpCenterViewModel({
    required String uid,
    required GetUserIssuesUseCase getUserIssuesUseCase,
    required SubmitIssueUseCase submitIssueUseCase,
  })  : _uid = uid,
        _getUserIssuesUseCase = getUserIssuesUseCase,
        _submitIssueUseCase = submitIssueUseCase {
    /// Loads data for the load issues operation.
    loadIssues();
  }

  // Getters
  bool get isLoading => _isLoading;
  /// Handles the is submitting operation.
  bool get isSubmitting => _isSubmitting;
  /// Handles the error message operation.
  String? get errorMessage => _errorMessage;
  /// Handles the issues operation.
  List<HelpCenterIssue> get issues => _filteredAndSortedIssues;
  /// Handles the filter status operation.
  String get filterStatus => _filterStatus;
  /// Handles the sort latest first operation.
  bool get sortLatestFirst => _sortLatestFirst;

  // Filtered and sorted issues
  List<HelpCenterIssue> get _filteredAndSortedIssues {
    // Apply filter
    List<HelpCenterIssue> filtered = _issues.where((issue) {
      if (_filterStatus == 'All') return true;
      if (_filterStatus == 'Replied') return issue.isReplied;
      return issue.isPending;
    }).toList();

    // Apply sort
    filtered.sort((a, b) {
      if (_sortLatestFirst) {
        return b.timestamp.compareTo(a.timestamp);
      } else {
        return a.timestamp.compareTo(b.timestamp);
      }
    });

    return filtered;
  }

  // Load user issues
  Future<void> loadIssues() async {
    _isLoading = true;
    notifyListeners();

    final result = await _getUserIssuesUseCase.execute(_uid);

    if (result.isLeft()) {
      _errorMessage = _getErrorMessage(result.left!);
      _issues = [];
    } else {
      _issues = result.right!;
      _errorMessage = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  // Submit new issue
  Future<bool> submitIssue(String message, File? imageFile) async {
    _isSubmitting = true;
    notifyListeners();

    final result = await _submitIssueUseCase.execute(
      uid: _uid,
      message: message,
      imageFile: imageFile,
    );

    if (result.isLeft()) {
      _errorMessage = _getErrorMessage(result.left!);
      _isSubmitting = false;
      notifyListeners();
      return false;
    }

    _isSubmitting = false;
    /// Loads data for the load issues operation.
    await loadIssues(); // Reload to show new issue
    return true;
  }

  // Change filter
  void setFilter(String filter) {
    _filterStatus = filter;
    notifyListeners();
  }

  // Toggle sort order
  void toggleSortOrder() {
    _sortLatestFirst = !_sortLatestFirst;
    notifyListeners();
  }

  /// Handles the get error message operation.
  String _getErrorMessage(Failure failure) {
    if (failure is ValidationFailure) {
      return failure.message;
    }
    if (failure is NetworkFailure) {
      return 'Network error. Please check your connection.';
    }
    return failure.message;
  }

  /// Handles the clear error operation.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
