import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../../../core/widgets/buttons/primary_button.dart';
import '../../../../../../app/dependency_injection/injection_container.dart';
import '../../../../domain/entities/help_center_issue.dart';
import '../../../../domain/usecases/get_user_issues_usecase.dart';
import '../../../../domain/usecases/submit_issue_usecase.dart';
import '../../../viewmodel/support/user_help_center_viewmodel.dart';
import '../../../widgets/support/issue_submission_form.dart';
import 'issue_detail_page.dart';

class UserHelpCenterPage extends StatelessWidget {
  const UserHelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
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

class _UserHelpCenterPageView extends StatelessWidget {
  const _UserHelpCenterPageView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<UserHelpCenterViewModel>();

    return Scaffold(
      appBar: const CustomAppBar(title: 'Help Center', centerTitle: true),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Anything wrong? State it and we will get back to you as soon as possible through your email!',
              style: TextStyle(fontSize: 16),
            ),
          ),
          _buildFilterSortRow(context, viewModel),
          Expanded(child: _buildIssuesList(context, viewModel)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSubmissionForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterSortRow(BuildContext context, UserHelpCenterViewModel viewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 0, 0),
          child: DropdownButton<String>(
            value: viewModel.filterStatus,
            items: const [
              DropdownMenuItem(value: 'All', child: Text('All')),
              DropdownMenuItem(value: 'Replied', child: Text('Replied')),
              DropdownMenuItem(value: 'Pending', child: Text('Pending')),
            ],
            onChanged: (value) => viewModel.setFilter(value!),
          ),
        ),
        IconButton(
          icon: Icon(viewModel.sortLatestFirst ? Icons.arrow_downward : Icons.arrow_upward),
          onPressed: viewModel.toggleSortOrder,
        ),
      ],
    );
  }

  Widget _buildIssuesList(BuildContext context, UserHelpCenterViewModel viewModel) {
    if (viewModel.issues.isEmpty) {
      return const Center(child: Text('No submissions yet'));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: viewModel.issues.length,
      itemBuilder: (context, index) {
        final issue = viewModel.issues[index];
        return _buildIssueItem(context, issue);
      },
    );
  }

  Widget _buildIssueItem(BuildContext context, HelpCenterIssue issue) {
    final formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(issue.timestamp);

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(issue.message, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Text(formattedDate, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    const SizedBox(height: 4),
                    _buildStatusBadge(issue.isReplied),
                  ],
                ),
              ),
              if (issue.imageUrl != null) ...[
                const SizedBox(width: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(issue.imageUrl!, width: 80, height: 80, fit: BoxFit.cover),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isReplied) {
    return Row(
      children: [
        Icon(isReplied ? Icons.check_circle : Icons.pending, color: isReplied ? Colors.green : Colors.orange, size: 16),
        const SizedBox(width: 4),
        Text(
          isReplied ? 'Replied' : 'Pending',
          style: TextStyle(fontSize: 12, color: isReplied ? Colors.green : Colors.orange, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _navigateToIssueDetail(BuildContext context, HelpCenterIssue issue) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => IssueDetailPage(issue: issue)),
    );
  }

  void _showSubmissionForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => IssueSubmissionForm(
        onSubmit: () => context.read<UserHelpCenterViewModel>().loadIssues(),
      ),
    );
  }
}