import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import '../../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../../core/widgets/buttons/primary_button.dart';
import '../../../../domain/entities/faq_item.dart';

class FaqFormPage extends StatefulWidget {
  final FaqItem? item;
  final Future<bool> Function({
    required String question,
    required String answer,
    File? questionImageFile,
    File? answerImageFile,
  }) onSave;

  const FaqFormPage({
    super.key,
    this.item,
    required this.onSave,
  });

  @override
  State<FaqFormPage> createState() => _FaqFormPageState();
}

class _FaqFormPageState extends State<FaqFormPage> {
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();

  File? _questionImageFile;
  File? _answerImageFile;
  String? _questionImageUrl;
  String? _answerImageUrl;

  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _questionController.text = widget.item!.question;
      _answerController.text = widget.item!.answer;
      _questionImageUrl = widget.item!.questionImageUrl;
      _answerImageUrl = widget.item!.answerImageUrl;
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isQuestion) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (isQuestion) {
          _questionImageFile = File(pickedFile.path);
        } else {
          _answerImageFile = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final success = await widget.onSave(
      question: _questionController.text.trim(),
      answer: _answerController.text.trim(),
      questionImageFile: _questionImageFile,
      answerImageFile: _answerImageFile,
    );

    if (success && mounted) {
      Navigator.pop(context);
    }

    if (mounted) {
      setState(() => _isSaving = false);
    }
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

  Widget _buildImagePreview({
    required String? existingUrl,
    required File? newFile,
    required bool isQuestion,
    required VoidCallback onRemove,
  }) {
    if (newFile != null) {
      return _buildImagePreviewWithRemove(
        path: newFile.path,
        isNetwork: false,
        onRemove: onRemove,
      );
    }
    if (existingUrl != null) {
      return _buildImagePreviewWithRemove(
        path: existingUrl,
        isNetwork: true,
        onRemove: onRemove,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildImagePreviewWithRemove({
    required String path,
    required bool isNetwork,
    required VoidCallback onRemove,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: () => isNetwork ? _showFullImage(context, path) : null,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: isNetwork
                  ? Image.network(path, height: 120, width: double.infinity, fit: BoxFit.contain)
                  : Image.file(File(path), height: 120, width: double.infinity, fit: BoxFit.contain),
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

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;

    return Scaffold(
      appBar: CustomAppBar(
        title: '${isEditing ? 'Edit' : 'Add'} FAQ',
        centerTitle: true,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (!_isSaving)
            TextButton(
              onPressed: _save,
              child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Section
            const Text('Question', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _questionController,
              maxLines: 3,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: () => _pickImage(true),
                ),
              ),
            ),
            _buildImagePreview(
              existingUrl: _questionImageUrl,
              newFile: _questionImageFile,
              isQuestion: true,
              onRemove: () => setState(() {
                _questionImageFile = null;
                _questionImageUrl = null;
              }),
            ),
            const SizedBox(height: 24),

            // Answer Section
            const Text('Answer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _answerController,
              maxLines: 6,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: () => _pickImage(false),
                ),
              ),
            ),
            _buildImagePreview(
              existingUrl: _answerImageUrl,
              newFile: _answerImageFile,
              isQuestion: false,
              onRemove: () => setState(() {
                _answerImageFile = null;
                _answerImageUrl = null;
              }),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24),
        child: PrimaryButton(
          text: isEditing ? 'Update' : 'Add',
          onPressed: _isSaving ? null : _save,
          isLoading: _isSaving,
        ),
      ),
    );
  }
}