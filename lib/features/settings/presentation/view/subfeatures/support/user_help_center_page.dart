// Builds the user help center screen.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../../../app/routers/app_router.dart';
import '../../../../../../app/routers/router_args.dart';
import '../../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../../../app/dependency_injection/injection_container.dart';
import '../../../../domain/entities/help_center_issue.dart';
import '../../../../domain/usecases/support/help_center/get_user_issues_usecase.dart';
import '../../../../domain/usecases/support/help_center/submit_issue_usecase.dart';
import '../../../viewmodel/support/user_help_center_viewmodel.dart';
import '../../../widgets/support/issue_submission_form.dart';

/// Defines behavior for user help center page.
class UserHelpCenterPage extends StatelessWidget {
  /// Creates a user help center page instance.
  const UserHelpCenterPage({super.key});

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    /// Runs the change notifier provider operation.
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
class _UserHelpCenterPageView extends StatelessWidget {
  /// Handles the user help center page view operation.
  const _UserHelpCenterPageView();

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<UserHelpCenterViewModel>();

    /// Handles the scaffold operation.
    return Scaffold(
      appBar: const CustomAppBar(title: 'Help Center', centerTitle: true),
      body: viewModel.isLoading
          ? const LoadingDialog()
          : Column(
              children: [
                /// Creates a padding instance.
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Anything wrong? State it and we will get back to you as soon as possible through your email!',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                _buildFilterSortRow(context, viewModel),

                /// Creates a expanded instance.
                Expanded(child: _buildIssuesList(context, viewModel)),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSubmissionForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Handles the build filter sort row operation.
  Widget _buildFilterSortRow(
    BuildContext context,
    UserHelpCenterViewModel viewModel,
  ) {
    /// Handles the row operation.
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        /// Creates a padding instance.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 0, 0),
          child: DropdownButton<String>(
            value: viewModel.filterStatus,
            items: const [
              /// Creates a dropdown menu item instance.
              DropdownMenuItem(value: 'All', child: Text('All')),

              /// Creates a dropdown menu item instance.
              DropdownMenuItem(value: 'Replied', child: Text('Replied')),

              /// Creates a dropdown menu item instance.
              DropdownMenuItem(value: 'Pending', child: Text('Pending')),
            ],
            onChanged: (value) => viewModel.setFilter(value!),
          ),
        ),

        /// Creates a icon button instance.
        IconButton(
          icon: Icon(
            viewModel.sortLatestFirst
                ? Icons.arrow_downward
                : Icons.arrow_upward,
          ),
          onPressed: viewModel.toggleSortOrder,
        ),
      ],
    );
  }

  /// Handles the build issues list operation.
  Widget _buildIssuesList(
    BuildContext context,
    UserHelpCenterViewModel viewModel,
  ) {
    if (viewModel.issues.isEmpty) {
      /// Handles the center operation.
      return const Center(child: Text('No submissions yet'));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: viewModel.issues.length,
      itemBuilder: (context, index) {
        final issue = viewModel.issues[index];

        /// Handles the build issue item operation.
        return _buildIssueItem(context, issue);
      },
    );
  }

  /// Handles the build issue item operation.
  Widget _buildIssueItem(BuildContext context, HelpCenterIssue issue) {
    final formattedDate = DateFormat(
      'MMM dd, yyyy • hh:mm a',
    ).format(issue.timestamp);

    /// Handles the container operation.
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.withOpacity(0.4), width: 1),
        color: Theme.of(context).cardColor,
      ),
      child: InkWell(
        onTap: () => _navigateToIssueDetail(context, issue),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              /// Creates a expanded instance.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Creates a text instance.
                    Text(
                      issue.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    /// Creates a sized box instance.
                    const SizedBox(height: 8),

                    /// Creates a text instance.
                    Text(
                      formattedDate,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),

                    /// Creates a sized box instance.
                    const SizedBox(height: 4),
                    _buildStatusBadge(issue.isReplied),
                  ],
                ),
              ),
              if (issue.imageUrl != null) ...[
                /// Creates a sized box instance.
                const SizedBox(width: 8),

                /// Creates a clip rrect instance.
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    issue.imageUrl!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Handles the build status badge operation.
  Widget _buildStatusBadge(bool isReplied) {
    /// Handles the row operation.
    return Row(
      children: [
        /// Creates a icon instance.
        Icon(
          isReplied ? Icons.check_circle : Icons.pending,
          color: isReplied ? Colors.green : Colors.orange,
          size: 16,
        ),

        /// Creates a sized box instance.
        const SizedBox(width: 4),

        /// Creates a text instance.
        Text(
          isReplied ? 'Replied' : 'Pending',
          style: TextStyle(
            fontSize: 12,
            color: isReplied ? Colors.green : Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Handles the navigate to issue detail operation.
  void _navigateToIssueDetail(BuildContext context, HelpCenterIssue issue) {
    context.push(AppRouter.issueDetail, extra: IssueDetailArgs(issue: issue));
  }

  /// Handles the show submission form operation.
  void _showSubmissionForm(BuildContext context) {
    final viewModel = context.read<UserHelpCenterViewModel>();

    /// Displays the show modal bottom sheet flow.
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
