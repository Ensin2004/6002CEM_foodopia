import 'package:flutter/foundation.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/extensions/either_extensions.dart';
import '../../../domain/usecases/about/get_about_content_usecase.dart';
import '../../../domain/usecases/about/save_about_content_usecase.dart';
import '../../../domain/usecases/about/delete_about_content_usecase.dart';

/// Defines behavior for about editor view model.
class AboutEditorViewModel extends ChangeNotifier {
  final GetAboutContentUseCase _getAboutContentUseCase;
  final SaveAboutContentUseCase _saveAboutContentUseCase;
  final DeleteAboutContentUseCase _deleteAboutContentUseCase;
  final String _documentId;
  final String _title;

  // State
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  String? _errorMessage;
  String _content = '';
  bool _hasChanges = false;

  /// Creates a about editor view model instance.
  AboutEditorViewModel({
    required String documentId,
    required String title,
    required GetAboutContentUseCase getAboutContentUseCase,
    required SaveAboutContentUseCase saveAboutContentUseCase,
    required DeleteAboutContentUseCase deleteAboutContentUseCase,
  }) : _documentId = documentId,
       _title = title,
       _getAboutContentUseCase = getAboutContentUseCase,
       _saveAboutContentUseCase = saveAboutContentUseCase,
       _deleteAboutContentUseCase = deleteAboutContentUseCase {
    /// Loads data for the load content operation.
    loadContent();
  }

  // Getters
  bool get isLoading => _isLoading;

  /// Handles the is saving operation.
  bool get isSaving => _isSaving;

  /// Handles the error message operation.
  String? get errorMessage => _errorMessage;

  bool get isEditing => _isEditing;

  /// Handles the content operation.
  String get content => _content;

  /// Handles the title operation.
  String get title => _title;

  /// Handles the has changes operation.
  bool get hasChanges => _hasChanges;

  /// Handles the is save disabled operation.
  bool get isSaveDisabled => _isSaving || !_isEditing;

  void startEditing() {
    _isEditing = true;
    _errorMessage = null;
    notifyListeners();
  }

  void cancelEditing() {
    _isEditing = false;
    _hasChanges = false;
    loadContent();
  }

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
    _isEditing = false;
    _isSaving = false;
    notifyListeners();
    return true;
  }

  Future<bool> deleteContent() async {
    _isSaving = true;
    notifyListeners();

    final result = await _deleteAboutContentUseCase.execute(_documentId);
    if (result.isLeft()) {
      _errorMessage = _getErrorMessage(result.left!);
      _isSaving = false;
      notifyListeners();
      return false;
    }

    _content = '';
    _hasChanges = false;
    _isEditing = false;
    _isSaving = false;
    notifyListeners();
    return true;
  }

  /// Handles the get error message operation.
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

  /// Handles the clear error operation.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
