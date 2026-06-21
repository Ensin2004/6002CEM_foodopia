import 'package:flutter/material.dart';

import '../viewmodel/settings_viewmodel.dart';

/// Profile summary shown at the top of the settings page.
class SettingsProfileHeader extends StatelessWidget {
  /// Settings state source.
  final SettingsViewModel viewModel;

  /// Creates the settings profile header.
  const SettingsProfileHeader({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    /* Header uses the same gradient as the existing settings page.
       Avatar falls back to the person icon when no profile image exists. */
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.yellow.shade100],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Theme.of(context).colorScheme.surface,
            backgroundImage: viewModel.profileImageUrl != null
                ? NetworkImage(viewModel.profileImageUrl!)
                : null,
            child: viewModel.profileImageUrl == null
                ? Icon(
                    Icons.person,
                    size: 40,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Full name line.
                Text(
                  viewModel.fullName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Email line.
                Text(
                  viewModel.email,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
