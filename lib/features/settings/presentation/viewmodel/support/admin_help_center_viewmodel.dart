import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/extensions/either_extensions.dart';
import '../../../domain/entities/help_center_issue.dart';
import '../../../domain/usecases/account/get_user_email_usecase.dart';
import '../../../domain/usecases/support/help_center/get_admin_issues_usecase.dart';
import '../../../domain/usecases/support/help_center/reply_to_issue_usecase.dart';
import '../../../domain/usecases/support/help_center/update_issue_status_usecase.dart';

/// Defines behavior for admin help center view model.
class AdminHelpCenterViewModel extends ChangeNotifier {
  final GetAdminIssuesUseCase _getAdminIssuesUseCase;
  final UpdateIssueStatusUseCase _updateIssueStatusUseCase;
  final GetUserEmailUseCase _getUserEmailUseCase;
  final ReplyToIssueUseCase _replyToIssueUseCase;

  // State
  bool _isLoading = true;
  String? _errorMessage;
  List<HelpCenterIssue> _issues = [];
  String _statusFilter = 'All';
  bool _sortDescending = true;
  final Map<String, String> _userEmails = {};
  final Map<String, String> _userNames = {};
  final Map<String, String?> _userProfileImages = {};

  /// Creates a admin help center view model instance.
  AdminHelpCenterViewModel({
    required GetAdminIssuesUseCase getAdminIssuesUseCase,
    required UpdateIssueStatusUseCase updateIssueStatusUseCase,
    required GetUserEmailUseCase getUserEmailUseCase,
    required ReplyToIssueUseCase replyToIssueUseCase,
  }) : _getAdminIssuesUseCase = getAdminIssuesUseCase,
       _updateIssueStatusUseCase = updateIssueStatusUseCase,
       _getUserEmailUseCase = getUserEmailUseCase,
       _replyToIssueUseCase = replyToIssueUseCase {
    /// Loads data for the load issues operation.
    loadIssues();
  }

  // Getters
  bool get isLoading => _isLoading;

  /// Handles the error message operation.
  String? get errorMessage => _errorMessage;

  /// Handles the issues operation.
  List<HelpCenterIssue> get issues => _filteredAndSortedIssues;

  /// Handles the status filter operation.
  String get statusFilter => _statusFilter;

  /// Handles the sort descending operation.
  bool get sortDescending => _sortDescending;

  // Filtered and sorted issues
  List<HelpCenterIssue> get _filteredAndSortedIssues {
    // Apply filter
    List<HelpCenterIssue> filtered = _issues.where((issue) {
      if (_statusFilter == 'All') return true;
      return issue.normalizedStatus == _statusFilter.toLowerCase();
    }).toList();

    // Apply sort
    filtered.sort((a, b) {
      if (_sortDescending) {
        return b.timestamp.compareTo(a.timestamp);
      } else {
        return a.timestamp.compareTo(b.timestamp);
      }
    });

    return filtered;
  }

  // Load all issues
  Future<void> loadIssues() async {
    _isLoading = true;
    notifyListeners();

    final result = await _getAdminIssuesUseCase.execute();

    if (result.isLeft()) {
      _errorMessage = _getErrorMessage(result.left!);
      _issues = [];
    } else {
      _issues = result.right!;
      await _loadUserProfiles();
      _errorMessage = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadUserProfiles() async {
    final uniqueUids = _issues.map((i) => i.uid).toSet();
    for (final uid in uniqueUids) {
      final result = await _getUserEmailUseCase.execute(uid);
      if (result.isRight() && result.right != null) {
        _userEmails[uid] = result.right!;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = doc.data();
      final name = data?['name']?.toString().trim();
      if (name != null && name.isNotEmpty) {
        _userNames[uid] = name;
      } else {
        final firstName = data?['firstName']?.toString() ?? '';
        final lastName = data?['lastName']?.toString() ?? '';
        final fullName = '$firstName $lastName'.trim();
        _userNames[uid] = fullName.isEmpty ? 'User' : fullName;
      }
      _userProfileImages[uid] = data?['profileImage']?.toString();
    }
  }

  // Get user email by UID
  String getUserEmail(String uid) {
    return _userEmails[uid] ?? '';
  }

  String getUserName(String uid) {
    return _userNames[uid] ?? 'User';
  }

  String? getUserProfileImage(String uid) {
    return _userProfileImages[uid];
  }

  // Mark issue as replied
  Future<void> markIssueAsReplied(String issueId) async {
    final result = await _updateIssueStatusUseCase.execute(issueId);
    if (result.isLeft()) {
      _errorMessage = _getErrorMessage(result.left!);
    } else {
      /// Loads data for the load issues operation.
      await loadIssues(); // Reload to update status
    }
  }

  Future<bool> replyToIssue(HelpCenterIssue issue, String reply) async {
    final result = await _replyToIssueUseCase.execute(
      issueId: issue.id,
      userUid: issue.uid,
      reply: reply,
    );
    if (result.isLeft()) {
      _errorMessage = _getErrorMessage(result.left!);
      notifyListeners();
      return false;
    }
    await loadIssues();
    return true;
  }

  // Change filter
  void setStatusFilter(String filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  // Toggle sort order
  void toggleSortOrder() {
    _sortDescending = !_sortDescending;
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
