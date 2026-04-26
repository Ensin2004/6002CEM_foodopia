import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../../../core/widgets/buttons/primary_button.dart';
import '../../../../../../app/dependency_injection/injection_container.dart';
import '../../../../domain/entities/help_center_issue.dart';
import '../../../../domain/usecases/get_admin_issues_usecase.dart';
import '../../../../domain/usecases/get_user_email_usecase.dart';
import '../../../../domain/usecases/update_issue_status_usecase.dart';
import '../../../viewmodel/support/admin_help_center_viewmodel.dart';
import 'issue_detail_page.dart';
import 'package:intl/intl.dart';

class AdminHelpCenterPage extends StatelessWidget {
  const AdminHelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
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

class _AdminHelpCenterPageView extends StatelessWidget {
  const _AdminHelpCenterPageView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminHelpCenterViewModel>();

    return Scaffold(
      appBar: const CustomAppBar(title: 'Admin Help Center', centerTitle: true),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildFilterControls(context, viewModel),
          Expanded(child: _buildIssuesList(context, viewModel)),
        ],
      ),
    );
  }

  Widget _buildFilterControls(BuildContext context, AdminHelpCenterViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          DropdownButton<String>(
            value: viewModel.statusFilter,
            items: const [
              DropdownMenuItem(value: 'All', child: Text('All')),
              DropdownMenuItem(value: 'Pending', child: Text('Pending')),
              DropdownMenuItem(value: 'Replied', child: Text('Replied')),
            ],
            onChanged: (value) => viewModel.setStatusFilter(value!),
          ),
          const Spacer(),
          Row(
            children: [
              const Text("Sort by: ", style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildIssuesList(BuildContext context, AdminHelpCenterViewModel viewModel) {
    if (viewModel.issues.isEmpty) {
      return const Center(child: Text('No submissions'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: viewModel.issues.length,
      itemBuilder: (context, index) {
        final issue = viewModel.issues[index];
        return _buildIssueItem(context, viewModel, issue);
      },
    );
  }

  Widget _buildIssueItem(BuildContext context, AdminHelpCenterViewModel viewModel, HelpCenterIssue issue) {
    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(issue.timestamp);

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

  Widget _buildIssueImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const Icon(Icons.image_not_supported);
    }
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

  void _navigateToIssueDetail(BuildContext context, AdminHelpCenterViewModel viewModel, HelpCenterIssue issue) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IssueDetailPage(
          issue: issue,
          userEmail: viewModel.getUserEmail(issue.uid),
          isAdmin: true,
          onStatusChanged: () => viewModel.loadIssues(),
        ),
      ),
    );
  }
}