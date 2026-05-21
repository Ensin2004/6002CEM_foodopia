import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../../app/dependency_injection/injection_container.dart';
import '../../../../../../app/routers/app_router.dart';
import '../../../../../../app/routers/router_args.dart';
import '../../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../../core/widgets/buttons/primary_button.dart';
import '../../../../../../core/widgets/buttons/secondary_button.dart';
import '../../../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../domain/usecases/support/rating/delete_rating_usecase.dart';
import '../../../../domain/usecases/support/rating/get_user_rating_usecase.dart';
import '../../../../domain/usecases/support/rating/save_rating_usecase.dart';
import '../../../viewmodel/support/rate_us_viewmodel.dart';

/// Defines behavior for rate us page.
class RateUsPage extends StatelessWidget {
  /// Creates a rate us page instance.
  const RateUsPage({super.key});

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    /// Runs the change notifier provider operation.
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

/// Defines behavior for rate us page view.
class _RateUsPageView extends StatefulWidget {
  /// Handles the rate us page view operation.
  const _RateUsPageView();

  /// Creates data for the create state operation.
  @override
  State<_RateUsPageView> createState() => _RateUsPageViewState();
}

/// Defines behavior for rate us page view state.
class _RateUsPageViewState extends State<_RateUsPageView> {
  File? _selectedImageFile;
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _commentController = TextEditingController();

  /// Releases resources before widget removal.
  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RateUsViewModel>();
    _syncCommentController(viewModel.comment);

    /// Handles the scaffold operation.
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: const CustomAppBar(title: 'Rate Us & Feedback', centerTitle: true),
      body: viewModel.isLoading
          ? const LoadingDialog()
          : Padding(
        padding: const EdgeInsets.all(16),
        child: viewModel.hasSubmittedRating && !viewModel.isEditing
            ? _buildRatingView(context, viewModel)
            : _buildRatingForm(context, viewModel),
      ),
    );
  }

  // Star builder
  Widget _buildStarIcon(BuildContext context, int starIndex, {bool isInteractive = true}) {
    final viewModel = context.watch<RateUsViewModel>();
    /// Handles the icon button operation.
    return IconButton(
      icon: Icon(
        starIndex <= viewModel.selectedStars ? Icons.star : Icons.star_border,
        size: 40,
        color: starIndex <= viewModel.selectedStars
            ? Theme.of(context).colorScheme.primary
            : Colors.grey[300],
      ),
      onPressed: isInteractive ? () => viewModel.setStars(starIndex) : null,
    );
  }

  // Rating View (read-only)
  Widget _buildRatingView(BuildContext context, RateUsViewModel viewModel) {
    /// Handles the column operation.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Creates a text instance.
        const Text('Your Rating', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        /// Creates a sized box instance.
        const SizedBox(height: 12),
        /// Creates a row instance.
        Row(children: List.generate(5, (index) => _buildStarIcon(context, index + 1, isInteractive: false))),
        /// Creates a sized box instance.
        const SizedBox(height: 16),
        if (viewModel.imageUrl != null) _buildStoredImagePreview(context, viewModel.imageUrl!),
        if (viewModel.imageUrl != null) const SizedBox(height: 16),
        /// Creates a text instance.
        Text(viewModel.comment, style: const TextStyle(fontSize: 16)),
        /// Creates a spacer instance.
        const Spacer(),
        /// Creates a primary button instance.
        PrimaryButton(text: 'Modify', onPressed: viewModel.startEditing),
        /// Creates a sized box instance.
        const SizedBox(height: 12),
        /// Creates a secondary button instance.
        SecondaryButton(text: 'Delete', onPressed: () => _showDeleteDialog(context, viewModel)),
      ],
    );
  }

  /// Handles the build stored image preview operation.
  Widget _buildStoredImagePreview(BuildContext context, String imageUrl) {
    /// Handles the center operation.
    return Center(
      child: GestureDetector(
        onTap: () => _showFullImage(context, imageUrl),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(imageUrl, height: 150, fit: BoxFit.contain),
        ),
      ),
    );
  }

  // Rating Form (edit/create)
  Widget _buildRatingForm(BuildContext context, RateUsViewModel viewModel) {
    /// Handles the single child scroll view operation.
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Creates a center instance.
          const Center(
            child: Text('Please rate your experience to help us improve!', style: TextStyle(fontSize: 16)),
          ),
          /// Creates a sized box instance.
          const SizedBox(height: 8),
          /// Creates a center instance.
          Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (index) => _buildStarIcon(context, index + 1)))),
          /// Creates a sized box instance.
          const SizedBox(height: 24),
          /// Creates a text field instance.
          TextField(
            controller: _commentController,
            onChanged: viewModel.setComment,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Tell us what you think…',
              prefixIcon: IconButton(
                icon: const Icon(Icons.image),
                onPressed: () async {
                  final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    setState(() => _selectedImageFile = File(pickedFile.path));
                  }
                },
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          if (viewModel.imageUrl != null && _selectedImageFile == null)
            _buildImagePreviewWithRemove(context, isNetwork: true, imagePath: viewModel.imageUrl!, onRemove: viewModel.removeStoredImage),
          if (_selectedImageFile != null)
            _buildImagePreviewWithRemove(
              context,
              isNetwork: false,
              imagePath: _selectedImageFile!.path,
              onRemove: () => setState(() => _selectedImageFile = null),
            ),
          /// Creates a sized box instance.
          const SizedBox(height: 30),
          if (viewModel.errorMessage != null) _buildErrorMessage(viewModel.errorMessage!),
          /// Creates a sized box instance.
          const SizedBox(height: 8),
          /// Creates a primary button instance.
          PrimaryButton(
            text: viewModel.hasSubmittedRating ? 'Update' : 'Submit',
            isLoading: viewModel.isSaving,
            onPressed: viewModel.isSubmitDisabled
                ? null
                : () async {
                    final success = await viewModel.saveRating(
                      imageFile: _selectedImageFile,
                    );
                    if (success && mounted) {
                      setState(() => _selectedImageFile = null);
                    }
                  },
          ),
          if (viewModel.hasSubmittedRating)
            /// Creates a padding instance.
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SecondaryButton(
                text: 'Cancel',
                onPressed: () {
                  setState(() => _selectedImageFile = null);
                  viewModel.cancelEditing();
                },
              ),
            ),
        ],
      ),
    );
  }

  /// Handles the build image preview with remove operation.
  Widget _buildImagePreviewWithRemove(BuildContext context, {required bool isNetwork, required String imagePath, required VoidCallback onRemove}) {
    /// Handles the padding operation.
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          /// Creates a gesture detector instance.
          GestureDetector(
            onTap: () => _showFullImage(context, imagePath),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: isNetwork
                  ? Image.network(imagePath, height: 150, width: double.infinity, fit: BoxFit.contain)
                  : Image.file(File(imagePath), height: 150, width: double.infinity, fit: BoxFit.contain),
            ),
          ),
          /// Creates a positioned instance.
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Handles the build error message operation.
  Widget _buildErrorMessage(String message) {
    /// Handles the container operation.
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
      child: Row(
        children: [
          /// Creates a icon instance.
          Icon(Icons.error_outline, color: Colors.red.shade700),
          /// Creates a sized box instance.
          const SizedBox(width: 8),
          /// Creates a expanded instance.
          Expanded(child: Text(message, style: TextStyle(color: Colors.red.shade700))),
        ],
      ),
    );
  }

  /// Handles the show full image operation.
  void _showFullImage(BuildContext context, String imageUrl) {
    context.push(
      AppRouter.imagePreview,
      extra: ImagePreviewArgs(imageUrl: imageUrl),
    );
  }

  /// Handles the show delete dialog operation.
  void _showDeleteDialog(BuildContext context, RateUsViewModel viewModel) {
    /// Displays the show dialog flow.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Rating'),
        content: const Text('Are you sure you want to delete your rating?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          /// Creates a text button instance.
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          /// Creates a text button instance.
          TextButton(
            onPressed: () async {
              await viewModel.deleteRating();
              if (mounted) setState(() => _selectedImageFile = null);
              if (context.mounted) Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Handles the sync comment controller operation.
  void _syncCommentController(String comment) {
    if (_commentController.text == comment) return;

    _commentController.value = TextEditingValue(
      text: comment,
      selection: TextSelection.collapsed(offset: comment.length),
    );
  }
}
