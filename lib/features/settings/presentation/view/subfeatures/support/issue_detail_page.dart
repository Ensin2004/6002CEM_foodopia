import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../../app/routers/app_router.dart';
import '../../../../../../app/routers/router_args.dart';
import '../../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../../core/widgets/buttons/primary_button.dart';
import '../../../../domain/entities/help_center_issue.dart';
import '../../../viewmodel/support/admin_help_center_viewmodel.dart';

/// Defines behavior for issue detail page.
class IssueDetailPage extends StatelessWidget {
  final HelpCenterIssue issue;
  final String? userEmail;
  final bool isAdmin;
  final VoidCallback? onStatusChanged;

  /// Creates a issue detail page instance.
  const IssueDetailPage({
    super.key,
    required this.issue,
    this.userEmail,
    this.isAdmin = false,
    this.onStatusChanged,
  });

  /// Handles the format date time operation.
  String _formatDateTime(DateTime dateTime) {
    /// Handles the date format operation.
    return DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime);
  }

  // Fix: Pass BuildContext as parameter
  Future<void> _launchEmail(BuildContext context) async {
    final emailUri = Uri(
      scheme: 'mailto',
      path: userEmail,
      queryParameters: {'subject': 'Re: Support Issue'},
    );
    if (await canLaunchUrl(emailUri)) {
      /// Handles the launch url operation.
      await launchUrl(emailUri);
      if (isAdmin && onStatusChanged != null) {
        // Context value is available
        await context.read<AdminHelpCenterViewModel>().markIssueAsReplied(issue.id);
        onStatusChanged!();
      }
    }
  }

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    /// Handles the scaffold operation.
    return Scaffold(
      appBar: CustomAppBar(title: 'Issue Details', centerTitle: true),
      body: Stack(
        children: [
          /// Creates a single child scroll view instance.
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Creates a text instance.
                Text(_formatDateTime(issue.timestamp), style: const TextStyle(color: Colors.grey)),
                /// Creates a sized box instance.
                const SizedBox(height: 16),
                /// Creates a row instance.
                Row(
                  children: [
                    /// Creates a icon instance.
                    Icon(issue.isReplied ? Icons.check_circle : Icons.pending,
                        color: issue.isReplied ? Colors.green : Colors.orange),
                    /// Creates a sized box instance.
                    const SizedBox(width: 4),
                    /// Creates a text instance.
                    Text(issue.isReplied ? 'Replied' : 'Pending',
                        style: TextStyle(color: issue.isReplied ? Colors.green : Colors.orange)),
                  ],
                ),
                /// Creates a sized box instance.
                const SizedBox(height: 16),
                /// Creates a text instance.
                Text(issue.message, style: const TextStyle(fontSize: 16)),
                if (issue.imageUrl != null) ...[
                  /// Creates a sized box instance.
                  const SizedBox(height: 16),
                  /// Creates a gesture detector instance.
                  GestureDetector(
                    onTap: () => _showFullScreenImage(context, issue.imageUrl!),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(issue.imageUrl!, width: double.infinity, height: 200, fit: BoxFit.cover),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isAdmin && !issue.isReplied)
            /// Creates a positioned instance.
            Positioned(
              left: 16,
              right: 16,
              bottom: 32,
              // Fix: Pass context to _launchEmail
              child: PrimaryButton(
                text: 'Reply via Email',
                onPressed: () => _launchEmail(context),
              ),
            ),
        ],
      ),
    );
  }

  /// Handles the show full screen image operation.
  void _showFullScreenImage(BuildContext context, String imageUrl) {
    context.push(
      AppRouter.imagePreview,
      extra: ImagePreviewArgs(imageUrl: imageUrl),
    );
  }
}
