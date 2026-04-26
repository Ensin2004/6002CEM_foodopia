import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../../../core/widgets/buttons/primary_button.dart';
import '../../../../domain/entities/help_center_issue.dart';
import '../../../viewmodel/support/admin_help_center_viewmodel.dart';

class IssueDetailPage extends StatelessWidget {
  final HelpCenterIssue issue;
  final String? userEmail;
  final bool isAdmin;
  final VoidCallback? onStatusChanged;

  const IssueDetailPage({
    super.key,
    required this.issue,
    this.userEmail,
    this.isAdmin = false,
    this.onStatusChanged,
  });

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime);
  }

  // ✅ Fixed: Pass BuildContext as parameter
  Future<void> _launchEmail(BuildContext context) async {
    final emailUri = Uri(
      scheme: 'mailto',
      path: userEmail,
      queryParameters: {'subject': 'Re: Support Issue'},
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
      if (isAdmin && onStatusChanged != null) {
        // ✅ Now context is available
        await context.read<AdminHelpCenterViewModel>().markIssueAsReplied(issue.id);
        onStatusChanged!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Issue Details', centerTitle: true),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatDateTime(issue.timestamp), style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(issue.isReplied ? Icons.check_circle : Icons.pending,
                        color: issue.isReplied ? Colors.green : Colors.orange),
                    const SizedBox(width: 4),
                    Text(issue.isReplied ? 'Replied' : 'Pending',
                        style: TextStyle(color: issue.isReplied ? Colors.green : Colors.orange)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(issue.message, style: const TextStyle(fontSize: 16)),
                if (issue.imageUrl != null) ...[
                  const SizedBox(height: 16),
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
            Positioned(
              left: 16,
              right: 16,
              bottom: 32,
              // ✅ Fixed: Pass context to _launchEmail
              child: PrimaryButton(
                text: 'Reply via Email',
                onPressed: () => _launchEmail(context),
              ),
            ),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(),
          body: Center(child: PhotoView(imageProvider: NetworkImage(imageUrl))),
        ),
      ),
    );
  }
}