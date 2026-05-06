import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../core/widgets/progress_bar/app_progress_bar.dart';
import '../viewmodel/user_setup_viewmodel.dart';

class UserSetupScaffold extends StatelessWidget {
  final int step;
  final String title;
  final String buttonText;
  final bool isSaving;
  final bool showProgress;
  final VoidCallback onContinue;
  final VoidCallback? onBack;
  final Widget child;

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
                  if (showProgress) ...[
                    AppProgressBar(
                      totalSteps: UserSetupViewModel.totalSteps,
                      currentStep: step,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  Text(title, style: context.text.titleLarge),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(child: child),
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
        if (isSaving) const LoadingDialog(),
      ],
    );
  }
}
