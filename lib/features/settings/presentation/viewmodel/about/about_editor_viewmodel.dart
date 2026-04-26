import 'package:flutter/material.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/extensions/either_extensions.dart';
import '../../../domain/entities/about_content.dart';
import '../../../domain/usecases/get_about_content_usecase.dart';
import '../../../domain/usecases/save_about_content_usecase.dart';

class AboutEditorViewModel extends ChangeNotifier {
  final GetAboutContentUseCase _getAboutContentUseCase;
  final SaveAboutContentUseCase _saveAboutContentUseCase;
  final String _documentId;
  final String _title;

  // ✅ Add TextEditingController
  final TextEditingController contentController = TextEditingController();

  // State
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String _content = '';
  bool _hasChanges = false;

  AboutEditorViewModel({
    required String documentId,
    required String title,
    required GetAboutContentUseCase getAboutContentUseCase,
    required SaveAboutContentUseCase saveAboutContentUseCase,
  })  : _documentId = documentId,
        _title = title,
        _getAboutContentUseCase = getAboutContentUseCase,
        _saveAboutContentUseCase = saveAboutContentUseCase {
    loadContent();
  }

  // Getters
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String get content => _content;
  String get title => _title;
  bool get hasChanges => _hasChanges;
  bool get isSaveDisabled => _isSaving || _content.trim().isEmpty;

  // Load content
  Future<void> loadContent() async {
    _isLoading = true;
    notifyListeners();

    final result = await _getAboutContentUseCase.execute(_documentId);

    if (result.isLeft()) {
      _errorMessage = _getErrorMessage(result.left!);
      _content = '';
      _isLoading = false;
      notifyListeners();
    } else {
      final aboutContent = result.right;
      _content = aboutContent?.content ?? '';
      // ✅ Update controller text
      contentController.text = _content;
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update content locally (called from text field)
  void updateContent(String newContent) {
    _content = newContent;
    _hasChanges = true;
    notifyListeners();
  }

  // Save content
  Future<bool> saveContent() async {
    if (_content.trim().isEmpty) {
      _errorMessage = 'Content cannot be empty';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    notifyListeners();

    final result = await _saveAboutContentUseCase.execute(
      documentId: _documentId,
      content: _content,
    );

    if (result.isLeft()) {
      _errorMessage = _getErrorMessage(result.left!);
      _isSaving = false;
      notifyListeners();
      return false;
    }

    _hasChanges = false;
    _isSaving = false;
    notifyListeners();
    return true;
  }

  String _getErrorMessage(Failure failure) {
    if (failure is NotFoundFailure) {
      return 'Document not found';
    }
    if (failure is ValidationFailure) {
      return failure.message;
    }
    if (failure is NetworkFailure) {
      return 'Network error. Please check your connection.';
    }
    return failure.message;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    contentController.dispose();
    super.dispose();
  }
}