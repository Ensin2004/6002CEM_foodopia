import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../../app/dependency_injection/injection_container.dart';
import '../../../../../../app/routers/app_router.dart';
import '../../../../../../app/routers/router_args.dart';
import '../../../../../../core/widgets/buttons/primary_button.dart';
import '../../../../../../core/widgets/custom_app_bar.dart';
import '../../../../domain/entities/help_center_issue.dart';
import '../../../../domain/usecases/support/help_center/reply_to_issue_usecase.dart';
import '../../../../domain/usecases/support/help_center/update_issue_status_usecase.dart';

class IssueDetailPage extends StatefulWidget {
  final HelpCenterIssue issue;
  final String? userEmail;
  final String? userName;
  final bool isAdmin;
  final VoidCallback? onStatusChanged;

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

class _IssueDetailPageState extends State<IssueDetailPage> {
  final _replyController = TextEditingController();
  bool _isSaving = false;
  String? _errorMessage;
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
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: const CustomAppBar(title: 'Issue Details', centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isAdmin) _buildUserHeader(context),
              _InfoRow(label: 'Ticket ID', value: _issue.id),
              _InfoRow(label: 'Date', value: _formatDateTime(_issue.timestamp)),
              _buildStatus(),
              const SizedBox(height: 18),
              Text('Message', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                _issue.message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (_issue.imageUrl?.isNotEmpty == true) ...[
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => _showFullScreenImage(context, _issue.imageUrl!),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _issue.imageUrl!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              if (widget.isAdmin)
                _buildAdminReplyBox(context)
              else
                _buildUserReply(context),
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

  Widget _buildUserHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const CircleAvatar(child: Icon(Icons.person_outline)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName ?? 'User',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (widget.userEmail?.isNotEmpty == true)
                  Text(
                    widget.userEmail!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatus() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Icon(
            _issue.isReplied ? Icons.check_circle : Icons.pending,
            color: _issue.isReplied ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 6),
          Text(
            _issue.isReplied ? 'Completed' : 'Pending',
            style: TextStyle(
              color: _issue.isReplied ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminReplyBox(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Admin Reply', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _replyController,
          minLines: 4,
          maxLines: 7,
          decoration: const InputDecoration(
            hintText: 'Write a reply for the user',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),
        PrimaryButton(
          text: _issue.isReplied ? 'Update Reply' : 'Reply User',
          isLoading: _isSaving,
          onPressed: _isSaving ? null : _replyToUser,
        ),
        const SizedBox(height: 10),
        if (!_issue.isReplied)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _isSaving ? null : _markAsComplete,
              child: const Text('Mark as Complete'),
            ),
          ),
      ],
    );
  }

  Widget _buildUserReply(BuildContext context) {
    if (_issue.adminReply.trim().isEmpty) {
      return Text(
        'No admin reply yet.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Admin Reply', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(_issue.adminReply),
          if (_issue.repliedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              _formatDateTime(_issue.repliedAt!),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _replyToUser() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    final result = await sl<ReplyToIssueUseCase>().execute(
      issueId: _issue.id,
      userUid: _issue.uid,
      reply: _replyController.text,
    );
    result.fold((failure) => _errorMessage = failure.message, (_) {
      _issue = _issue.copyWith(
        replied: true,
        adminReply: _replyController.text.trim(),
        repliedAt: DateTime.now(),
      );
      widget.onStatusChanged?.call();
    });
    if (mounted) setState(() => _isSaving = false);
  }

  Future<void> _markAsComplete() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    final result = await sl<UpdateIssueStatusUseCase>().execute(_issue.id);
    result.fold((failure) => _errorMessage = failure.message, (_) {
      _issue = _issue.copyWith(replied: true, repliedAt: DateTime.now());
      widget.onStatusChanged?.call();
    });
    if (mounted) setState(() => _isSaving = false);
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy - hh:mm a').format(dateTime);
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    context.push(
      AppRouter.imagePreview,
      extra: ImagePreviewArgs(imageUrl: imageUrl),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
