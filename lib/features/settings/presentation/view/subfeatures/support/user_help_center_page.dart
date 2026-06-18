// Builds the user help center screen.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../../../app/dependency_injection/injection_container.dart';
import '../../../../../../app/routers/app_router.dart';
import '../../../../../../app/routers/router_args.dart';
import '../../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../domain/entities/help_center_issue.dart';
import '../../../../domain/usecases/support/help_center/get_user_issues_usecase.dart';
import '../../../../domain/usecases/support/help_center/submit_issue_usecase.dart';
import '../../../viewmodel/support/user_help_center_viewmodel.dart';
import '../../../widgets/support/help_center_common_widgets.dart';
import '../../../widgets/support/issue_submission_form.dart';

/// Defines behavior for user help center page.
/// Displays user's help tickets with filtering and sorting.
class UserHelpCenterPage extends StatelessWidget {
  /// Creates a user help center page instance.
  const UserHelpCenterPage({super.key});

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    // Get the current user ID.
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // Provide the view model to the widget tree.
    return ChangeNotifierProvider(
      create: (_) => UserHelpCenterViewModel(
        uid: uid,
        getUserIssuesUseCase: sl<GetUserIssuesUseCase>(),
        submitIssueUseCase: sl<SubmitIssueUseCase>(),
      ),
      child: const _UserHelpCenterPageView(),
    );
  }
}

/// Defines behavior for user help center page view.
class _UserHelpCenterPageView extends StatefulWidget {
  /// Handles the user help center page view operation.
  const _UserHelpCenterPageView();

  @override
  State<_UserHelpCenterPageView> createState() =>
      _UserHelpCenterPageViewState();
}

/// State for the user help center page view.
class _UserHelpCenterPageViewState extends State<_UserHelpCenterPageView> {
  /// Controller for the search text field.
  final TextEditingController _searchController = TextEditingController();

  /// Current search query.
  String _searchQuery = '';

  @override
  void dispose() {
    // Dispose the search controller.
    _searchController.dispose();
    super.dispose();
  }

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<UserHelpCenterViewModel>();

    // Get the theme for styling.
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        title: 'Help Center',
        centerTitle: true,
        elevation: 6,
        toolbarHeight: 76,
        foregroundColor: Color(0xFF0B1730),
      ),
      body: viewModel.isLoading
          ? const LoadingDialog()
          : Column(
              children: [
                _buildHeroCard(),
                _buildFilterSortRow(context, viewModel),
                Expanded(child: _buildIssuesList(context, viewModel)),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_help_ticket',
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 10,
        shape: const CircleBorder(),
        onPressed: () => _showSubmissionForm(context),
        child: const Icon(Icons.add, size: 34),
      ),
    );
  }

  // =========================================================================
  // HERO CARD
  // =========================================================================

  /// Builds the hero card with header and search field.
  Widget _buildHeroCard() {
    return HelpCenterHeroCard(
      title: 'How can we help you?',
      message:
          "Tell us what's wrong and we'll get back to you as soon as possible.",
      searchField: _buildSearchField(),
    );
  }

  /// Builds the search field.
  Widget _buildSearchField() {
    return HelpCenterSearchField(
      controller: _searchController,
      searchQuery: _searchQuery,
      hintText: 'Search your tickets...',
      onChanged: (value) => setState(() => _searchQuery = value.trim()),
      onClear: () {
        _searchController.clear();
        setState(() => _searchQuery = '');
      },
    );
  }

  // =========================================================================
  // FILTER AND SORT
  // =========================================================================

  /// Handles the build filter sort row operation.
  Widget _buildFilterSortRow(
    BuildContext context,
    UserHelpCenterViewModel viewModel,
  ) {
    return HelpCenterFilterSortRow(
      selectedStatus: viewModel.filterStatus,
      sortLatestFirst: viewModel.sortLatestFirst,
      onStatusSelected: viewModel.setFilter,
      onSortSelected: (latestFirst) {
        if (viewModel.sortLatestFirst != latestFirst) {
          viewModel.toggleSortOrder();
        }
      },
    );
  }

  // =========================================================================
  // ISSUES LIST
  // =========================================================================

  /// Handles the build issues list operation.
  Widget _buildIssuesList(
    BuildContext context,
    UserHelpCenterViewModel viewModel,
  ) {
    // Get visible issues based on search query.
    final issues = _visibleIssues(viewModel.issues);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
      children: [
        // Show empty state if no issues.
        if (issues.isEmpty)
          HelpCenterEmptyTicketsCard(
            title: _searchQuery.isEmpty
                ? 'No more tickets'
                : 'No tickets found',
            message: _searchQuery.isEmpty
                ? "You're all caught up. If you need more help, we're here for you."
                : 'Try another ticket ID, date, or message.',
          )
        else ...[
          // Build each issue item.
          for (final issue in issues) _buildIssueItem(context, issue),
        ],
      ],
    );
  }

  /// Filters issues based on the search query.
  List<HelpCenterIssue> _visibleIssues(List<HelpCenterIssue> issues) {
    // Get the search query.
    final query = _searchQuery.toLowerCase();

    // Return all issues if query is empty.
    if (query.isEmpty) return issues;

    // Filter issues by search query.
    return issues.where((issue) {
      final formattedDate = DateFormat(
        'MMM dd, yyyy hh:mm a',
      ).format(issue.timestamp).toLowerCase();

      // Search in ID, message, admin reply, and date.
      return issue.id.toLowerCase().contains(query) ||
          issue.message.toLowerCase().contains(query) ||
          issue.adminReply.toLowerCase().contains(query) ||
          formattedDate.contains(query);
    }).toList();
  }

  /// Handles the build issue item operation.
  Widget _buildIssueItem(BuildContext context, HelpCenterIssue issue) {
    // Get the theme for styling.
    final theme = Theme.of(context);

    // Format the timestamp.
    final formattedDate = DateFormat(
      'MMM dd, yyyy - hh:mm a',
    ).format(issue.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6E9EE)),
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _navigateToIssueDetail(context, issue),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ticket ID.
                    Text(
                      'Ticket ID: ${issue.id}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Status badge and view icon.
                    Row(
                      children: [
                        HelpCenterStatusBadge(issue: issue),
                        const Spacer(),
                        const Icon(
                          Icons.visibility_outlined,
                          color: Color(0xFF5F6673),
                          size: 24,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Timestamp.
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: Color(0xFF6E7480),
                          size: 17,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            formattedDate,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // NAVIGATION
  // =========================================================================

  /// Handles the navigate to issue detail operation.
  void _navigateToIssueDetail(BuildContext context, HelpCenterIssue issue) {
    context.push(AppRouter.issueDetail, extra: IssueDetailArgs(issue: issue));
  }

  /// Handles the show submission form operation.
  void _showSubmissionForm(BuildContext context) {
    // Get the view model.
    final viewModel = context.read<UserHelpCenterViewModel>();

    // Show the bottom sheet with the submission form.
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: viewModel,
        child: IssueSubmissionForm(onSubmit: viewModel.loadIssues),
      ),
    );
  }
}
