// Builds the admin help center screen.

import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../../../app/dependency_injection/injection_container.dart';
import '../../../../../../app/routers/app_router.dart';
import '../../../../../../app/routers/router_args.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../domain/entities/help_center_issue.dart';
import '../../../../domain/usecases/account/get_user_email_usecase.dart';
import '../../../../domain/usecases/support/help_center/get_admin_issues_usecase.dart';
import '../../../../domain/usecases/support/help_center/reply_to_issue_usecase.dart';
import '../../../../domain/usecases/support/help_center/update_issue_status_usecase.dart';
import '../../../viewmodel/support/admin_help_center_viewmodel.dart';

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
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 22, 18, 14),
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF8F0), Color(0xFFE2F4E9), Color(0xFFF4FBF6)],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -4,
            top: 6,
            child: IgnorePointer(
              child: Image.asset(
                'assets/images/help_center.png',
                width: 132,
                height: 142,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 142),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Support tickets',
                  style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                    fontSize: 26,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Review user tickets, reply quickly, and keep every issue moving.',
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
                ),
                const SizedBox(height: 22),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 164),
            child: _buildSearchField(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    final theme = Theme.of(context);

    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _searchQuery = value.trim()),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search tickets or users...',
        hintStyle: theme.inputDecorationTheme.hintStyle?.copyWith(fontSize: 14),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
          size: 22,
        ),
        suffixIcon: _searchQuery.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              ),
        filled: true,
        fillColor: theme.colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildFilterSortRow(
    BuildContext context,
    AdminHelpCenterViewModel viewModel,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChipButton(
                    label: 'All',
                    isSelected: viewModel.statusFilter == 'All',
                    onTap: () => viewModel.setStatusFilter('All'),
                  ),
                  const SizedBox(width: 12),
                  _FilterChipButton(
                    label: 'Open',
                    isSelected: viewModel.statusFilter == 'Open',
                    onTap: () => viewModel.setStatusFilter('Open'),
                  ),
                  const SizedBox(width: 12),
                  _FilterChipButton(
                    label: 'Closed',
                    isSelected: viewModel.statusFilter == 'Closed',
                    onTap: () => viewModel.setStatusFilter('Closed'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          _SortMenuButton(
            sortLatestFirst: viewModel.sortDescending,
            onSelected: (latestFirst) {
              if (viewModel.sortDescending != latestFirst) {
                viewModel.toggleSortOrder();
              }
            },
          ),
        ],
      ),
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
          _buildEmptyTicketsCard(
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
                        _buildStatusBadge(issue),
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

  Widget _buildStatusBadge(HelpCenterIssue issue) {
    final status = issue.normalizedStatus;
    final label = status == 'closed' ? 'Closed' : 'Open';
    final color = status == 'closed'
        ? const Color(0xFFE53935)
        : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTicketsCard({
    required String title,
    required String message,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 24, 12, 6),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: const Color(0xFFDDE3EA),
          radius: 18,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 28, 18, 30),
          child: Column(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF8F0),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: Color(0xFF81C991),
                  size: 34,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
              ),
            ],
          ),
        ),
      ),
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

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = isSelected
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : const Color(0xFFE3E6EB),
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(color: foreground),
          ),
        ),
      ),
    );
  }
}

class _SortMenuButton extends StatelessWidget {
  const _SortMenuButton({
    required this.sortLatestFirst,
    required this.onSelected,
  });

  final bool sortLatestFirst;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<bool>(
      tooltip: 'Sort tickets',
      onSelected: onSelected,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: true,
          child: Row(
            children: [
              Icon(
                Icons.check_rounded,
                size: 18,
                color: sortLatestFirst
                    ? theme.colorScheme.primary
                    : Colors.transparent,
              ),
              const SizedBox(width: 8),
              const Text('Newest'),
            ],
          ),
        ),
        PopupMenuItem(
          value: false,
          child: Row(
            children: [
              Icon(
                Icons.check_rounded,
                size: 18,
                color: !sortLatestFirst
                    ? theme.colorScheme.primary
                    : Colors.transparent,
              ),
              const SizedBox(width: 8),
              const Text('Oldest'),
            ],
          ),
        ),
      ],
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFFE3E6EB)),
        ),
        child: Icon(
          Icons.tune_rounded,
          color: theme.colorScheme.onSurface,
          size: 24,
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rect);

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      const dashWidth = 7.0;
      const dashSpace = 6.0;

      while (distance < metric.length) {
        final next = math.min(distance + dashWidth, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
