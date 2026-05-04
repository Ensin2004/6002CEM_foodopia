import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/extensions/either_extensions.dart';
import '../../../domain/entities/faq_item.dart';
import '../../../domain/usecases/support/faq/add_faq_item_usecase.dart';
import '../../../domain/usecases/support/faq/delete_faq_item_usecase.dart';
import '../../../domain/usecases/support/faq/get_admin_faq_items_usecase.dart';
import '../../../domain/usecases/support/faq/update_faq_item_usecase.dart';
import '../../../domain/usecases/support/faq/upload_faq_image_usecase.dart';

/// Defines behavior for admin faq view model.
class AdminFaqViewModel extends ChangeNotifier {
  final GetAdminFaqItemsUseCase _getAdminFaqItemsUseCase;
  final AddFaqItemUseCase _addFaqItemUseCase;
  final UpdateFaqItemUseCase _updateFaqItemUseCase;
  final DeleteFaqItemUseCase _deleteFaqItemUseCase;
  final UploadFaqImageUseCase _uploadFaqImageUseCase;

  // State
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  List<FaqItem> _items = [];
  List<FaqItem> _filteredItems = [];
  String _sortOption = 'newest';
  String _searchTerm = '';

  /// Creates a admin faq view model instance.
  AdminFaqViewModel({
    required GetAdminFaqItemsUseCase getAdminFaqItemsUseCase,
    required AddFaqItemUseCase addFaqItemUseCase,
    required UpdateFaqItemUseCase updateFaqItemUseCase,
    required DeleteFaqItemUseCase deleteFaqItemUseCase,
    required UploadFaqImageUseCase uploadFaqImageUseCase,
  })  : _getAdminFaqItemsUseCase = getAdminFaqItemsUseCase,
        _addFaqItemUseCase = addFaqItemUseCase,
        _updateFaqItemUseCase = updateFaqItemUseCase,
        _deleteFaqItemUseCase = deleteFaqItemUseCase,
        _uploadFaqImageUseCase = uploadFaqImageUseCase {
    /// Loads data for the load items operation.
    loadItems();
  }

  // Getters
  bool get isLoading => _isLoading;
  /// Handles the is saving operation.
  bool get isSaving => _isSaving;
  /// Handles the error message operation.
  String? get errorMessage => _errorMessage;
  /// Handles the filtered items operation.
  List<FaqItem> get filteredItems => _filteredItems;
  /// Handles the sort option operation.
  String get sortOption => _sortOption;
  /// Handles the search term operation.
  String get searchTerm => _searchTerm;

  // Load items
  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();

    final result = await _getAdminFaqItemsUseCase.execute();

    if (result.isLeft()) {
      _errorMessage = _getErrorMessage(result.left!);
      _items = [];
    } else {
      _items = result.right!;
      _errorMessage = null;
    }

    _applyFiltersAndSort();
    _isLoading = false;
    notifyListeners();
  }

  // Add item
  Future<bool> addItem({
    required String question,
    required String answer,
    File? questionImageFile,
    File? answerImageFile,
  }) async {
    _isSaving = true;
    notifyListeners();

    final result = await _addFaqItemUseCase.execute(
      question: question,
      answer: answer,
      questionImageFile: questionImageFile,
      answerImageFile: answerImageFile,
    );

    if (result.isLeft()) {
      _errorMessage = _getErrorMessage(result.left!);
      _isSaving = false;
      notifyListeners();
      return false;
    }

    /// Loads data for the load items operation.
    await loadItems();
    _isSaving = false;
    notifyListeners();
    return true;
  }

  // Update item
  Future<bool> updateItem({
    required String id,
    required String question,
    required String answer,
    String? existingQuestionImageUrl,
    String? existingAnswerImageUrl,
    File? newQuestionImageFile,
    File? newAnswerImageFile,
  }) async {
    _isSaving = true;
    notifyListeners();

    final result = await _updateFaqItemUseCase.execute(
      id: id,
      question: question,
      answer: answer,
      existingQuestionImageUrl: existingQuestionImageUrl,
      existingAnswerImageUrl: existingAnswerImageUrl,
      newQuestionImageFile: newQuestionImageFile,
      newAnswerImageFile: newAnswerImageFile,
    );

    if (result.isLeft()) {
      _errorMessage = _getErrorMessage(result.left!);
      _isSaving = false;
      notifyListeners();
      return false;
    }

    /// Loads data for the load items operation.
    await loadItems();
    _isSaving = false;
    notifyListeners();
    return true;
  }

  // Delete item
  Future<bool> deleteItem(String id) async {
    _isSaving = true;
    notifyListeners();

    final result = await _deleteFaqItemUseCase.execute(id);

    if (result.isLeft()) {
      _errorMessage = _getErrorMessage(result.left!);
      _isSaving = false;
      notifyListeners();
      return false;
    }

    /// Loads data for the load items operation.
    await loadItems();
    _isSaving = false;
    notifyListeners();
    return true;
  }

  // Upload image
  Future<String?> uploadImage(File imageFile) async {
    final result = await _uploadFaqImageUseCase.execute(imageFile);
    if (result.isLeft()) {
      _errorMessage = _getErrorMessage(result.left!);
      return null;
    }
    return result.right;
  }

  // Apply filters and sorting
  void _applyFiltersAndSort() {
    var filtered = List<FaqItem>.from(_items);

    // Apply search filter
    if (_searchTerm.isNotEmpty) {
      filtered = filtered.where((item) {
        return item.question.toLowerCase().contains(_searchTerm.toLowerCase());
      }).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      switch (_sortOption) {
        case 'oldest':
          return a.createdAt.compareTo(b.createdAt);
        case 'a-z':
          return a.question.compareTo(b.question);
        case 'z-a':
          return b.question.compareTo(a.question);
        default: // 'newest'
          return b.createdAt.compareTo(a.createdAt);
      }
    });

    _filteredItems = filtered;
    notifyListeners();
  }

  // Set sort option
  void setSortOption(String option) {
    _sortOption = option;
    _applyFiltersAndSort();
  }

  // Set search term
  void setSearchTerm(String term) {
    _searchTerm = term;
    _applyFiltersAndSort();
  }

  /// Handles the get error message operation.
  String _getErrorMessage(Failure failure) {
    if (failure is ValidationFailure) {
      return failure.message;
    }
    if (failure is NetworkFailure) {
      return 'Network error. Please check your connection.';
    }
    return failure.message;
  }
}
