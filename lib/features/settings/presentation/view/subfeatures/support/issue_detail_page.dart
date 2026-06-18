import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../../app/dependency_injection/injection_container.dart';
import '../../../../../../app/routers/app_router.dart';
import '../../../../../../app/routers/router_args.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/widgets/buttons/primary_button.dart';
import '../../../../../../core/widgets/custom_app_bar.dart';
import '../../../../domain/entities/help_center_issue.dart';
import '../../../../domain/usecases/support/help_center/reply_to_issue_usecase.dart';
import '../../../../domain/usecases/support/help_center/update_issue_status_usecase.dart';

/// Page for viewing and managing a help center issue detail.
/// Supports both user and admin views with reply functionality.
class IssueDetailPage extends StatefulWidget {
  /// The help center issue to display.
  final HelpCenterIssue issue;

  /// Email of the user who submitted the issue.
  final String? userEmail;

  /// Name of the user who submitted the issue.
  final String? userName;

  /// Whether the current user is an admin.
  final bool isAdmin;

  /// Callback when issue status changes.
  final VoidCallback? onStatusChanged;

  /// Creates a new issue detail page instance.
  const IssueDetailPage({
    super.key,
    required this.issue,
    this.userEmail,
    this.userName,
    this.isAdmin = false,
    this.onStatusChanged,
  });

  @override
  State<IssueDetailPage> createState() => _IssueDetailPageState();
}

/// State for the issue detail page.
class _IssueDetailPageState extends State<IssueDetailPage> {
  /// Controller for the reply text field.
  final _replyController = TextEditingController();

  /// Whether saving is in progress.
  bool _isSaving = false;

  /// Error message to display.
  String? _errorMessage;

  /// Mutable copy of the issue for local updates.
  late HelpCenterIssue _issue;

  @override
  void initState() {
    super.initState();
    _issue = widget.issue;
    _replyController.text = _issue.adminReply;
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the theme.
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: const CustomAppBar(title: 'Issue Details', centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User header (admin only).
              if (widget.isAdmin) _buildUserHeader(context),

              // Summary card.
              _buildSummaryCard(context),
              const SizedBox(height: 16),

              // Message section.
              _buildSectionCard(
                context: context,
                title: 'Message',
                icon: Icons.chat_bubble_outline_rounded,
                child: Text(
                  _issue.message,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
                ),
              ),

              // Attachment section.
              if (_issue.imageUrl?.isNotEmpty == true) ...[
                const SizedBox(height: 16),
                _buildSectionCard(
                  context: context,
                  title: 'Attachment',
                  icon: Icons.image_outlined,
                  child: _buildAttachment(context, _issue.imageUrl!),
                ),
              ],
              const SizedBox(height: 16),

              // Reply section (admin or user view).
              if (widget.isAdmin)
                _buildAdminReplyBox(context)
              else
                _buildUserReply(context),

              // Error message.
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the user header for admin view.
  Widget _buildUserHeader(BuildContext context) {
    final theme = Theme.of(context);

    return _buildSectionCard(
      context: context,
      title: 'Submitted by',
      icon: Icons.person_outline_rounded,
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
            child: Icon(
              Icons.person_outline_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName ?? 'User',
                  style: theme.textTheme.titleMedium,
                ),
                if (widget.userEmail?.isNotEmpty == true)
                  Text(
                    widget.userEmail!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the summary card with ticket details.
  Widget _buildSummaryCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6E9EE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildDetailStatusBadge(context),
              const Spacer(),
              Icon(
                Icons.confirmation_number_outlined,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Ticket ID.
          Text(
            'Ticket ID',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            _issue.id,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),

          // Timestamp.
          _buildMetaLine(
            context,
            icon: Icons.calendar_today_outlined,
            text: _formatDateTime(_issue.timestamp),
          ),

          // Replied timestamp if available.
          if (_issue.repliedAt != null) ...[
            const SizedBox(height: 8),
            _buildMetaLine(
              context,
              icon: Icons.mark_email_read_outlined,
              text: 'Closed ${_formatDateTime(_issue.repliedAt!)}',
            ),
          ],
        ],
      ),
    );
  }

  /// Builds the status badge for the issue.
  Widget _buildDetailStatusBadge(BuildContext context) {
    final theme = Theme.of(context);
    final isClosed = _issue.normalizedStatus == 'closed';
    final color = isClosed ? AppColors.error : theme.colorScheme.primary;
    final label = isClosed ? 'Closed' : 'Open';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
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
            style: theme.textTheme.labelLarge?.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  /// Builds a meta line with icon and text.
  Widget _buildMetaLine(
      BuildContext context, {
        required IconData icon,
        required String text,
      }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
          size: 17,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// Builds a section card with title and content.
  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Widget child,
    EdgeInsetsGeometry? margin,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6E9EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  /// Builds the attachment widget.
  Widget _buildAttachment(BuildContext context, String imageUrl) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(context, imageUrl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Image.network(
              imageUrl,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.58),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.open_in_full_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                    SizedBox(width: 6),
                    Text('View', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the admin reply box.
  Widget _buildAdminReplyBox(BuildContext context) {
    return _buildSectionCard(
      context: context,
      title: 'Admin Reply',
      icon: Icons.support_agent_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _replyController,
            minLines: 4,
            maxLines: 7,
            decoration: InputDecoration(
              hintText: 'Write a reply for the user',
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Reply button.
          PrimaryButton(
            text: _issue.isReplied ? 'Update Reply' : 'Reply User',
            isLoading: _isSaving,
            onPressed: _isSaving ? null : _replyToUser,
          ),
          const SizedBox(height: 10),

          // Mark as closed button.
          if (!_issue.isReplied)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isSaving ? null : _markAsComplete,
                child: const Text('Mark as Closed'),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds the user reply view.
  Widget _buildUserReply(BuildContext context) {
    // Show empty state if no reply.
    if (_issue.adminReply.trim().isEmpty) {
      return _buildSectionCard(
        context: context,
        title: 'Admin Reply',
        icon: Icons.support_agent_rounded,
        child: Text(
          'No admin reply yet.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    // Show reply with timestamp.
    return _buildSectionCard(
      context: context,
      title: 'Admin Reply',
      icon: Icons.support_agent_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _issue.adminReply,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(height: 1.45),
          ),
          if (_issue.repliedAt != null) ...[
            const SizedBox(height: 12),
            _buildMetaLine(
              context,
              icon: Icons.schedule_rounded,
              text: _formatDateTime(_issue.repliedAt!),
            ),
          ],
        ],
      ),
    );
  }

  /// Replies to the user.
  Future<void> _replyToUser() async {
    // Set saving state.
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    // Execute the use case.
    final result = await sl<ReplyToIssueUseCase>().execute(
      issueId: _issue.id,
      userUid: _issue.uid,
      reply: _replyController.text,
    );

    // Handle result.
    result.fold(
          (failure) => _errorMessage = failure.message,
          (_) {
        // Update local issue state.
        _issue = _issue.copyWith(
          replied: true,
          status: 'closed',
          adminReply: _replyController.text.trim(),
          repliedAt: DateTime.now(),
        );
        widget.onStatusChanged?.call();
      },
    );

    // Reset saving state.
    if (mounted) setState(() => _isSaving = false);
  }

  /// Marks the issue as closed.
  Future<void> _markAsComplete() async {
    // Set saving state.
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    // Execute the use case.
    final result = await sl<UpdateIssueStatusUseCase>().execute(_issue.id);

    // Handle result.
    result.fold(
          (failure) => _errorMessage = failure.message,
          (_) {
        // Update local issue state.
        _issue = _issue.copyWith(
          replied: true,
          status: 'closed',
          repliedAt: DateTime.now(),
        );
        widget.onStatusChanged?.call();
      },
    );

    // Reset saving state.
    if (mounted) setState(() => _isSaving = false);
  }

  /// Formats a date time for display.
  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy - hh:mm a').format(dateTime);
  }

  /// Shows the full screen image preview.
  void _showFullScreenImage(BuildContext context, String imageUrl) {
    context.push(
      AppRouter.imagePreview,
      extra: ImagePreviewArgs(imageUrl: imageUrl),
    );
  }
}