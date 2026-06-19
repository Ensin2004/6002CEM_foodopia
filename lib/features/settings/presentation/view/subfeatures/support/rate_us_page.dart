import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../../../app/dependency_injection/injection_container.dart';
import '../../../../../../core/widgets/buttons/primary_button.dart';
import '../../../../../../core/widgets/buttons/secondary_button.dart';
import '../../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../domain/usecases/support/rating/delete_rating_usecase.dart';
import '../../../../domain/usecases/support/rating/get_user_rating_usecase.dart';
import '../../../../domain/usecases/support/rating/save_rating_usecase.dart';
import '../../../viewmodel/support/rate_us_viewmodel.dart';

/// Defines behavior for rate us page.
/// Allows users to rate the app and provide feedback.
class RateUsPage extends StatelessWidget {
  /// Creates a rate us page instance.
  const RateUsPage({super.key});

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    // Get the current user ID.
    final userId = FirebaseAuth.instance.currentUser!.uid;

    // Provide the view model to the widget tree.
    return ChangeNotifierProvider(
      create: (_) => RateUsViewModel(
        userId: userId,
        getUserRatingUseCase: sl<GetUserRatingUseCase>(),
        saveRatingUseCase: sl<SaveRatingUseCase>(),
        deleteRatingUseCase: sl<DeleteRatingUseCase>(),
      ),
      child: const _RateUsPageView(),
    );
  }
}

/// Internal view for the rate us page.
class _RateUsPageView extends StatefulWidget {
  /// Creates a new rate us page view instance.
  const _RateUsPageView();

  @override
  State<_RateUsPageView> createState() => _RateUsPageViewState();
}

/// State for the rate us page view.
class _RateUsPageViewState extends State<_RateUsPageView> {
  /// Controller for the comment text field.
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<RateUsViewModel>();

    // Sync the comment controller with the view model.
    _syncCommentController(viewModel.comment);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: const CustomAppBar(
        title: 'Rate Us & Feedback',
        centerTitle: true,
      ),
      body: viewModel.isLoading
          ? const LoadingDialog()
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
          child: viewModel.hasSubmittedRating && !viewModel.isEditing
              ? _buildRatingView(context, viewModel)
              : _buildRatingForm(context, viewModel),
        ),
      ),
    );
  }

  /// Builds the rating view for submitted ratings.
  Widget _buildRatingView(BuildContext context, RateUsViewModel viewModel) {
    final theme = Theme.of(context);
    final feedback = viewModel.comment.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Intro card.
        _buildIntroCard(
          context,
          title: 'Thanks for your feedback',
          subtitle: 'Your rating helps us keep Foodopia useful and friendly.',
        ),
        const SizedBox(height: 18),

        // Rating panel.
        _buildPanel(
          context: context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Rating',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              _buildStars(
                context,
                selectedStars: viewModel.selectedStars,
                isInteractive: false,
                onSelected: viewModel.setStars,
              ),
              const SizedBox(height: 18),
              Text(
                'Feedback',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                feedback.isEmpty ? 'No feedback provided.' : feedback,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // Action buttons.
        PrimaryButton(text: 'Modify', onPressed: viewModel.startEditing),
        const SizedBox(height: 12),
        SecondaryButton(
          text: 'Delete',
          onPressed: () => _showDeleteDialog(context, viewModel),
        ),
      ],
    );
  }

  /// Builds the rating form for new ratings.
  Widget _buildRatingForm(BuildContext context, RateUsViewModel viewModel) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Intro card.
        _buildIntroCard(
          context,
          title: 'How was your experience?',
          subtitle:
          'Tap a star to rate us. Feedback is optional, but always welcome.',
        ),
        const SizedBox(height: 18),

        // Rating panel.
        _buildPanel(
          context: context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildStars(
                context,
                selectedStars: viewModel.selectedStars,
                onSelected: viewModel.setStars,
              ),
              const SizedBox(height: 22),
              TextField(
                controller: _commentController,
                onChanged: viewModel.setComment,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Tell us what you think (optional)',
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // Error message.
        if (viewModel.errorMessage != null) ...[
          _buildErrorMessage(context, viewModel.errorMessage!),
          const SizedBox(height: 12),
        ],

        // Submit button.
        PrimaryButton(
          text: viewModel.hasSubmittedRating ? 'Update' : 'Submit',
          isLoading: viewModel.isSaving,
          onPressed: viewModel.isSubmitDisabled
              ? null
              : () async => viewModel.saveRating(),
        ),

        // Cancel button for editing.
        if (viewModel.hasSubmittedRating) ...[
          const SizedBox(height: 12),
          SecondaryButton(text: 'Cancel', onPressed: viewModel.cancelEditing),
        ],
      ],
    );
  }

  /// Builds the intro card.
  Widget _buildIntroCard(
      BuildContext context, {
        required String title,
        required String subtitle,
      }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF8E1), Color(0xFFFFFDF5)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.star_rounded, color: Colors.amber.shade600, size: 42),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }

  /// Builds a panel with card styling.
  Widget _buildPanel({required BuildContext context, required Widget child}) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6E9EE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  /// Builds the star rating widget.
  Widget _buildStars(
      BuildContext context, {
        required int selectedStars,
        required ValueChanged<int> onSelected,
        bool isInteractive = true,
      }) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      children: List.generate(5, (index) {
        final star = index + 1;
        final isFilled = star <= selectedStars;

        return IconButton(
          tooltip: '$star star${star == 1 ? '' : 's'}',
          icon: Icon(
            isFilled ? Icons.star_rounded : Icons.star_border_rounded,
            color: isFilled ? Colors.amber.shade600 : Colors.grey.shade300,
            size: 44,
          ),
          onPressed: isInteractive ? () => onSelected(star) : null,
        );
      }),
    );
  }

  /// Builds an error message widget.
  Widget _buildErrorMessage(BuildContext context, String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: Colors.red.shade700)),
          ),
        ],
      ),
    );
  }

  /// Shows the delete confirmation dialog.
  void _showDeleteDialog(BuildContext context, RateUsViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Rating'),
        content: const Text('Are you sure you want to delete your rating?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await viewModel.deleteRating();
              if (context.mounted) Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Syncs the comment controller with the view model.
  void _syncCommentController(String comment) {
    // Skip if already synced.
    if (_commentController.text == comment) return;

    // Update the controller.
    _commentController.value = TextEditingValue(
      text: comment,
      selection: TextSelection.collapsed(offset: comment.length),
    );
  }
}