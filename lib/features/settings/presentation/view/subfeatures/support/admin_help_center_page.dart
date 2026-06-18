// Builds the admin help center screen.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../../../app/dependency_injection/injection_container.dart';
import '../../../../../../app/routers/app_router.dart';
import '../../../../../../app/routers/router_args.dart';
import '../../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../domain/entities/help_center_issue.dart';
import '../../../../domain/usecases/account/get_user_email_usecase.dart';
import '../../../../domain/usecases/support/help_center/get_admin_issues_usecase.dart';
import '../../../../domain/usecases/support/help_center/reply_to_issue_usecase.dart';
import '../../../../domain/usecases/support/help_center/update_issue_status_usecase.dart';
import '../../../viewmodel/support/admin_help_center_viewmodel.dart';
import '../../../widgets/support/help_center_common_widgets.dart';

/// Defines behavior for admin help center page.
class AdminHelpCenterPage extends StatelessWidget {
  /// Creates a admin help center page instance.
  const AdminHelpCenterPage({super.key});

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminHelpCenterViewModel(
        getAdminIssuesUseCase: sl<GetAdminIssuesUseCase>(),
        updateIssueStatusUseCase: sl<UpdateIssueStatusUseCase>(),
        getUserEmailUseCase: sl<GetUserEmailUseCase>(),
        replyToIssueUseCase: sl<ReplyToIssueUseCase>(),
      ),
      child: const _AdminHelpCenterPageView(),
    );
  }
}

/// Defines behavior for admin help center page view.
class _AdminHelpCenterPageView extends StatefulWidget {
  /// Handles the admin help center page view operation.
  const _AdminHelpCenterPageView();

  @override
  State<_AdminHelpCenterPageView> createState() =>
      _AdminHelpCenterPageViewState();
}

class _AdminHelpCenterPageViewState extends State<_AdminHelpCenterPageView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminHelpCenterViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        title: 'Admin Help Center',
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
    );
  }

  Widget _buildHeroCard() {
    return HelpCenterHeroCard(
      title: 'Support tickets',
      message:
          'Review user tickets, reply quickly, and keep every issue moving.',
      searchField: _buildSearchField(),
    );
  }

  Widget _buildSearchField() {
    return HelpCenterSearchField(
      controller: _searchController,
      searchQuery: _searchQuery,
      hintText: 'Search tickets or users...',
      onChanged: (value) => setState(() => _searchQuery = value.trim()),
      onClear: () {
        _searchController.clear();
        setState(() => _searchQuery = '');
      },
    );
  }

  Widget _buildFilterSortRow(
    BuildContext context,
    AdminHelpCenterViewModel viewModel,
  ) {
    return HelpCenterFilterSortRow(
      selectedStatus: viewModel.statusFilter,
      sortLatestFirst: viewModel.sortDescending,
      onStatusSelected: viewModel.setStatusFilter,
      onSortSelected: (latestFirst) {
        if (viewModel.sortDescending != latestFirst) {
          viewModel.toggleSortOrder();
        }
      },
    );
  }

  Widget _buildIssuesList(
    BuildContext context,
    AdminHelpCenterViewModel viewModel,
  ) {
    final issues = _visibleIssues(viewModel);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
      children: [
        if (issues.isEmpty)
          HelpCenterEmptyTicketsCard(
            title: _searchQuery.isEmpty
                ? 'No more tickets'
                : 'No tickets found',
            message: _searchQuery.isEmpty
                ? "You're all caught up. New help tickets will appear here."
                : 'Try another ticket ID, user, date, or message.',
          )
        else ...[
          for (final issue in issues)
            _buildIssueItem(context, viewModel, issue),
        ],
      ],
    );
  }

  List<HelpCenterIssue> _visibleIssues(AdminHelpCenterViewModel viewModel) {
    final query = _searchQuery.toLowerCase();
    final issues = viewModel.issues;
    if (query.isEmpty) return issues;

    return issues.where((issue) {
      final formattedDate = DateFormat(
        'MMM dd, yyyy hh:mm a',
      ).format(issue.timestamp).toLowerCase();
      final name = viewModel.getUserName(issue.uid).toLowerCase();
      final email = viewModel.getUserEmail(issue.uid).toLowerCase();
      return issue.id.toLowerCase().contains(query) ||
          issue.message.toLowerCase().contains(query) ||
          issue.adminReply.toLowerCase().contains(query) ||
          name.contains(query) ||
          email.contains(query) ||
          formattedDate.contains(query);
    }).toList();
  }

  Widget _buildIssueItem(
    BuildContext context,
    AdminHelpCenterViewModel viewModel,
    HelpCenterIssue issue,
  ) {
    final theme = Theme.of(context);
    final formattedDate = DateFormat(
      'MMM dd, yyyy - hh:mm a',
    ).format(issue.timestamp);
    final profileImage = viewModel.getUserProfileImage(issue.uid);
    final name = viewModel.getUserName(issue.uid);
    final email = viewModel.getUserEmail(issue.uid);

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
        onTap: () => _navigateToIssueDetail(context, viewModel, issue),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserAvatar(profileImage, name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      'Ticket ID: ${issue.id}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
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

  Widget _buildUserAvatar(String? imageUrl, String name) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return CircleAvatar(
        radius: 24,
        child: Text(name.isEmpty ? 'U' : name.characters.first.toUpperCase()),
      );
    }
    return CircleAvatar(
      radius: 24,
      backgroundImage: CachedNetworkImageProvider(imageUrl),
      child: null,
    );
  }

  void _navigateToIssueDetail(
    BuildContext context,
    AdminHelpCenterViewModel viewModel,
    HelpCenterIssue issue,
  ) {
    context.push(
      AppRouter.issueDetail,
      extra: IssueDetailArgs(
        issue: issue,
        userEmail: viewModel.getUserEmail(issue.uid),
        userName: viewModel.getUserName(issue.uid),
        isAdmin: true,
        onStatusChanged: () => viewModel.loadIssues(),
      ),
    );
  }
}
