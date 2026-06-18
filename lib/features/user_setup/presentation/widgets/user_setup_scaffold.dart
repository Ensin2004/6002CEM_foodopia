import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../core/widgets/progress_bar/app_progress_bar.dart';
import '../viewmodel/user_setup_viewmodel.dart';

/// Scaffold for user setup pages.
/// Provides consistent layout with progress bar, title, and action button.
class UserSetupScaffold extends StatelessWidget {
  /// Current step number.
  final int step;

  /// Page title.
  final String title;

  /// Button text.
  final String buttonText;

  /// Whether saving is in progress.
  final bool isSaving;

  /// Whether to show the progress bar.
  final bool showProgress;

  /// Callback when continue button is pressed.
  final VoidCallback onContinue;

  /// Optional back button callback.
  final VoidCallback? onBack;

  /// Child widget content.
  final Widget child;

  /// Creates a new user setup scaffold instance.
  const UserSetupScaffold({
    super.key,
    required this.step,
    required this.title,
    required this.buttonText,
    required this.isSaving,
    this.showProgress = true,
    required this.onContinue,
    this.onBack,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button.
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                    onPressed:
                    onBack ??
                            () {
                          if (context.canPop()) context.pop();
                        },
                    icon: const Icon(Icons.arrow_back, size: 20),
                  ),

                  // Progress bar.
                  if (showProgress) ...[
                    AppProgressBar(
                      totalSteps: UserSetupViewModel.totalSteps,
                      currentStep: step,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Title.
                  Text(title, style: context.text.titleLarge),
                  const SizedBox(height: AppSpacing.md),

                  // Content.
                  Expanded(child: child),

                  // Continue button.
                  PrimaryButton(
                    onPressed: isSaving ? null : onContinue,
                    text: buttonText,
                    isLoading: isSaving,
                    borderRadius: const BorderRadius.all(Radius.circular(6)),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Loading overlay.
        if (isSaving) const LoadingDialog(),
      ],
    );
  }
}