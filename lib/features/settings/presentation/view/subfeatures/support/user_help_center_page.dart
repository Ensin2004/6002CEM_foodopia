// Builds the user help center screen.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../../../app/dependency_injection/injection_container.dart';
import '../../../../../../app/routers/app_router.dart';
import '../../../../../../app/routers/router_args.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../domain/entities/help_center_issue.dart';
import '../../../../domain/usecases/support/help_center/get_user_issues_usecase.dart';
import '../../../../domain/usecases/support/help_center/submit_issue_usecase.dart';
import '../../../viewmodel/support/user_help_center_viewmodel.dart';
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
    // Get the theme for styling.
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
          // Decorative image.
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
          // Text content.
          Padding(
            padding: const EdgeInsets.only(right: 142),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How can we help you?',
                  style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                    fontSize: 26,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  "Tell us what's wrong and we'll get back to you as soon as possible.",
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
                ),
                const SizedBox(height: 22),
              ],
            ),
          ),
          // Search field.
          Padding(
            padding: const EdgeInsets.only(top: 164),
            child: _buildSearchField(),
          ),
        ],
      ),
    );
  }

  /// Builds the search field.
  Widget _buildSearchField() {
    // Get the theme for styling.
    final theme = Theme.of(context);

    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _searchQuery = value.trim()),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search your tickets...',
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

  // =========================================================================
  // FILTER AND SORT
  // =========================================================================

  /// Handles the build filter sort row operation.
  Widget _buildFilterSortRow(
      BuildContext context,
      UserHelpCenterViewModel viewModel,
      ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Row(
        children: [
          // Filter chips.
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChipButton(
                    label: 'All',
                    isSelected: viewModel.filterStatus == 'All',
                    onTap: () => viewModel.setFilter('All'),
                  ),
                  const SizedBox(width: 12),
                  _FilterChipButton(
                    label: 'Open',
                    isSelected: viewModel.filterStatus == 'Open',
                    onTap: () => viewModel.setFilter('Open'),
                  ),
                  const SizedBox(width: 12),
                  _FilterChipButton(
                    label: 'Closed',
                    isSelected: viewModel.filterStatus == 'Closed',
                    onTap: () => viewModel.setFilter('Closed'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Sort menu button.
          _SortMenuButton(
            sortLatestFirst: viewModel.sortLatestFirst,
            onSelected: (latestFirst) {
              if (viewModel.sortLatestFirst != latestFirst) {
                viewModel.toggleSortOrder();
              }
            },
          ),
        ],
      ),
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
          _buildEmptyTicketsCard(
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

  /// Handles the build status badge operation.
  Widget _buildStatusBadge(HelpCenterIssue issue) {
    // Get the normalized status.
    final status = issue.normalizedStatus;

    // Determine label and color based on status.
    final label = switch (status) {
      'closed' => 'Closed',
      _ => 'Open',
    };
    final color = switch (status) {
      'closed' => const Color(0xFFE53935),
      _ => AppColors.primary,
    };

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

  // =========================================================================
  // EMPTY STATE
  // =========================================================================

  /// Builds the empty tickets card.
  Widget _buildEmptyTicketsCard({
    required String title,
    required String message,
  }) {
    // Get the theme for styling.
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
              // Icon container.
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

              // Title.
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),

              // Message.
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

// =============================================================================
// HELPER WIDGETS
// =============================================================================

/// Filter chip button widget.
class _FilterChipButton extends StatelessWidget {
  /// Label text.
  final String label;

  /// Whether the chip is selected.
  final bool isSelected;

  /// Callback when tapped.
  final VoidCallback onTap;

  /// Creates a new filter chip button instance.
  const _FilterChipButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Get the theme for styling.
    final theme = Theme.of(context);

    // Determine foreground color.
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sort menu button widget.
class _SortMenuButton extends StatelessWidget {
  /// Whether to sort latest first.
  final bool sortLatestFirst;

  /// Callback when sort order is selected.
  final ValueChanged<bool> onSelected;

  /// Creates a new sort menu button instance.
  const _SortMenuButton({
    required this.sortLatestFirst,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Get the theme for styling.
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

/// Dashed border painter for empty state cards.
class _DashedBorderPainter extends CustomPainter {
  /// Color of the dashed border.
  final Color color;

  /// Corner radius of the border.
  final double radius;

  /// Creates a new dashed border painter instance.
  const _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    // Create the paint for the dashed border.
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Create the rounded rectangle path.
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rect);

    // Draw dashed border along the path.
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