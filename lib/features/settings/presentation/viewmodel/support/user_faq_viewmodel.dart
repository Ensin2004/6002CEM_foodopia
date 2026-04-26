import 'package:flutter/material.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/extensions/either_extensions.dart';
import '../../../domain/entities/faq_item.dart';
import '../../../domain/usecases/get_user_faq_items_usecase.dart';

class UserFaqViewModel extends ChangeNotifier {
  final GetUserFaqItemsUseCase _getUserFaqItemsUseCase;

  // State
  bool _isLoading = true;
  String? _errorMessage;
  List<FaqItem> _items = [];

  UserFaqViewModel({
    required GetUserFaqItemsUseCase getUserFaqItemsUseCase,
  }) : _getUserFaqItemsUseCase = getUserFaqItemsUseCase {
    loadItems();
  }

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<FaqItem> get items => _items;

  // Load items
  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();

    final result = await _getUserFaqItemsUseCase.execute();

    if (result.isLeft()) {
      _errorMessage = _getErrorMessage(result.left!);
      _items = [];
    } else {
      _items = result.right!;
      _errorMessage = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  String _getErrorMessage(Failure failure) {
    if (failure is NetworkFailure) {
      return 'Network error. Please check your connection.';
    }
    return failure.message;
  }
}