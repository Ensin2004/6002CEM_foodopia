import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import '../../../../../../app/dependency_injection/injection_container.dart';
import '../../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../../core/widgets/buttons/primary_button.dart';
import '../../../../../../core/widgets/buttons/secondary_button.dart';
import '../../../../domain/usecases/get_user_rating_usecase.dart';
import '../../../../domain/usecases/save_rating_usecase.dart';
import '../../../../domain/usecases/delete_rating_usecase.dart';
import '../../../../domain/usecases/upload_rating_image_usecase.dart';
import '../../../viewmodel/support/rate_us_viewmodel.dart';

class RateUsPage extends StatelessWidget {
  const RateUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    return ChangeNotifierProvider(
      create: (_) => RateUsViewModel(
        userId: userId,
        getUserRatingUseCase: sl<GetUserRatingUseCase>(),
        saveRatingUseCase: sl<SaveRatingUseCase>(),
        deleteRatingUseCase: sl<DeleteRatingUseCase>(),
        uploadRatingImageUseCase: sl<UploadRatingImageUseCase>(),
      ),
      child: const _RateUsPageView(),
    );
  }
}

class _RateUsPageView extends StatelessWidget {
  const _RateUsPageView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RateUsViewModel>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: const CustomAppBar(title: 'Rate Us & Feedback', centerTitle: true),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your Rating', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(children: List.generate(5, (index) => _buildStarIcon(context, index + 1, isInteractive: false))),
        const SizedBox(height: 16),
        if (viewModel.imageUrl != null) _buildStoredImagePreview(context, viewModel.imageUrl!),
        if (viewModel.imageUrl != null) const SizedBox(height: 16),
        Text(viewModel.comment, style: const TextStyle(fontSize: 16)),
        const Spacer(),
        PrimaryButton(text: 'Modify', onPressed: viewModel.startEditing),
        const SizedBox(height: 12),
        SecondaryButton(text: 'Delete', onPressed: () => _showDeleteDialog(context, viewModel)),
      ],
    );
  }

  Widget _buildStoredImagePreview(BuildContext context, String imageUrl) {
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
    final imagePicker = ImagePicker();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text('Please rate your experience to help us improve!', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 8),
          Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (index) => _buildStarIcon(context, index + 1)))),
          const SizedBox(height: 24),
          TextField(
            controller: TextEditingController(text: viewModel.comment)..addListener(() => viewModel.setComment(TextEditingController(text: viewModel.comment).text)),
            onChanged: viewModel.setComment,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Tell us what you think…',
              prefixIcon: IconButton(
                icon: const Icon(Icons.image),
                onPressed: () async {
                  final pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) viewModel.pickImage(File(pickedFile.path));
                },
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          if (viewModel.imageUrl != null && viewModel.selectedImageFile == null)
            _buildImagePreviewWithRemove(context, isNetwork: true, imagePath: viewModel.imageUrl!, onRemove: viewModel.removeStoredImage),
          if (viewModel.selectedImageFile != null)
            _buildImagePreviewWithRemove(context, isNetwork: false, imagePath: viewModel.selectedImageFile!.path, onRemove: viewModel.removeSelectedImage),
          const SizedBox(height: 30),
          if (viewModel.errorMessage != null) _buildErrorMessage(viewModel.errorMessage!),
          const SizedBox(height: 8),
          PrimaryButton(
            text: viewModel.hasSubmittedRating ? 'Update' : 'Submit',
            isLoading: viewModel.isSaving,
            onPressed: viewModel.isSubmitDisabled ? null : viewModel.saveRating,
          ),
          if (viewModel.hasSubmittedRating)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SecondaryButton(text: 'Cancel', onPressed: viewModel.cancelEditing),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePreviewWithRemove(BuildContext context, {required bool isNetwork, required String imagePath, required VoidCallback onRemove}) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: () => _showFullImage(context, imagePath),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: isNetwork
                  ? Image.network(imagePath, height: 150, width: double.infinity, fit: BoxFit.contain)
                  : Image.file(File(imagePath), height: 150, width: double.infinity, fit: BoxFit.contain),
            ),
          ),
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

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: TextStyle(color: Colors.red.shade700))),
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
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

  void _showDeleteDialog(BuildContext context, RateUsViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Rating'),
        content: const Text('Are you sure you want to delete your rating?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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
}