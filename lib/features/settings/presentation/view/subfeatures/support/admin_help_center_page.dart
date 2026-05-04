// Builds the admin help center screen.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../../../app/routers/app_router.dart';
import '../../../../../../app/routers/router_args.dart';
import '../../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../../../app/dependency_injection/injection_container.dart';
import '../../../../domain/entities/help_center_issue.dart';
import '../../../../domain/usecases/account/get_user_email_usecase.dart';
import '../../../../domain/usecases/support/help_center/get_admin_issues_usecase.dart';
import '../../../../domain/usecases/support/help_center/update_issue_status_usecase.dart';
import '../../../viewmodel/support/admin_help_center_viewmodel.dart';
import 'package:intl/intl.dart';

/// Defines behavior for admin help center page.
class AdminHelpCenterPage extends StatelessWidget {
  /// Creates a admin help center page instance.
  const AdminHelpCenterPage({super.key});

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    /// Runs the change notifier provider operation.
    return ChangeNotifierProvider(
      create: (_) => AdminHelpCenterViewModel(
        getAdminIssuesUseCase: sl<GetAdminIssuesUseCase>(),
        updateIssueStatusUseCase: sl<UpdateIssueStatusUseCase>(),
        getUserEmailUseCase: sl<GetUserEmailUseCase>(),
      ),
      child: const _AdminHelpCenterPageView(),
    );
  }
}

/// Defines behavior for admin help center page view.
class _AdminHelpCenterPageView extends StatelessWidget {
  /// Handles the admin help center page view operation.
  const _AdminHelpCenterPageView();

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminHelpCenterViewModel>();

    /// Handles the scaffold operation.
    return Scaffold(
      appBar: const CustomAppBar(title: 'Admin Help Center', centerTitle: true),
      body: viewModel.isLoading
          ? const LoadingDialog()
          : Column(
        children: [
          _buildFilterControls(context, viewModel),
          /// Creates a expanded instance.
          Expanded(child: _buildIssuesList(context, viewModel)),
        ],
      ),
    );
  }

  /// Handles the build filter controls operation.
  Widget _buildFilterControls(BuildContext context, AdminHelpCenterViewModel viewModel) {
    /// Handles the padding operation.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          DropdownButton<String>(
            value: viewModel.statusFilter,
            items: const [
              /// Creates a dropdown menu item instance.
              DropdownMenuItem(value: 'All', child: Text('All')),
              /// Creates a dropdown menu item instance.
              DropdownMenuItem(value: 'Pending', child: Text('Pending')),
              /// Creates a dropdown menu item instance.
              DropdownMenuItem(value: 'Replied', child: Text('Replied')),
            ],
            onChanged: (value) => viewModel.setStatusFilter(value!),
          ),
          /// Creates a spacer instance.
          const Spacer(),
          /// Creates a row instance.
          Row(
            children: [
              /// Creates a text instance.
              const Text("Sort by: ", style: TextStyle(fontWeight: FontWeight.bold)),
              /// Creates a icon button instance.
              IconButton(
                tooltip: viewModel.sortDescending ? 'Latest' : 'Oldest',
                icon: Icon(viewModel.sortDescending ? Icons.arrow_downward : Icons.arrow_upward),
                onPressed: viewModel.toggleSortOrder,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Handles the build issues list operation.
  Widget _buildIssuesList(BuildContext context, AdminHelpCenterViewModel viewModel) {
    if (viewModel.issues.isEmpty) {
      /// Handles the center operation.
      return const Center(child: Text('No submissions'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: viewModel.issues.length,
      itemBuilder: (context, index) {
        final issue = viewModel.issues[index];
        /// Handles the build issue item operation.
        return _buildIssueItem(context, viewModel, issue);
      },
    );
  }

  /// Handles the build issue item operation.
  Widget _buildIssueItem(BuildContext context, AdminHelpCenterViewModel viewModel, HelpCenterIssue issue) {
    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(issue.timestamp);

    /// Handles the container operation.
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.withOpacity(0.4), width: 1),
        color: Theme.of(context).cardColor,
      ),
      child: ListTile(
        onTap: () => _navigateToIssueDetail(context, viewModel, issue),
        leading: _buildIssueImage(issue.imageUrl),
        title: Text(issue.message, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(formattedDate, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        trailing: Icon(issue.isReplied ? Icons.check_circle : Icons.pending, color: issue.isReplied ? Colors.green : Colors.orange),
      ),
    );
  }

  /// Handles the build issue image operation.
  Widget _buildIssueImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      /// Handles the icon operation.
      return const Icon(Icons.image_not_supported);
    }
    /// Handles the clip rrect operation.
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        placeholder: (_, __) => const CircularProgressIndicator(),
        errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
      ),
    );
  }

  /// Handles the navigate to issue detail operation.
  void _navigateToIssueDetail(BuildContext context, AdminHelpCenterViewModel viewModel, HelpCenterIssue issue) {
    context.push(
      AppRouter.issueDetail,
      extra: IssueDetailArgs(
        issue: issue,
        userEmail: viewModel.getUserEmail(issue.uid),
        isAdmin: true,
        onStatusChanged: () => viewModel.loadIssues(),
      ),
    );
  }
}
