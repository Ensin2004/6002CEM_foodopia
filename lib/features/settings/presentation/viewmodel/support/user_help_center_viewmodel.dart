import 'dart:io';

import 'package:flutter/material.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/extensions/either_extensions.dart';
import '../../../domain/entities/help_center_issue.dart';
import '../../../domain/usecases/get_user_issues_usecase.dart';
import '../../../domain/usecases/submit_issue_usecase.dart';

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

  UserHelpCenterViewModel({
    required String uid,
    required GetUserIssuesUseCase getUserIssuesUseCase,
    required SubmitIssueUseCase submitIssueUseCase,
  })  : _uid = uid,
        _getUserIssuesUseCase = getUserIssuesUseCase,
        _submitIssueUseCase = submitIssueUseCase {
    loadIssues();
  }

  // Getters
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  List<HelpCenterIssue> get issues => _filteredAndSortedIssues;
  String get filterStatus => _filterStatus;
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

  String _getErrorMessage(Failure failure) {
    if (failure is ValidationFailure) {
      return failure.message;
    }
    if (failure is NetworkFailure) {
      return 'Network error. Please check your connection.';
    }
    return failure.message;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}