import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/extensions/either_extensions.dart';
import '../../../domain/entities/faq_item.dart';
import '../../../domain/usecases/support/faq/get_user_faq_items_usecase.dart';

/// Defines behavior for user faq view model.
class UserFaqViewModel extends ChangeNotifier {
  final GetUserFaqItemsUseCase _getUserFaqItemsUseCase;

  // State
  bool _isLoading = true;
  String? _errorMessage;
  List<FaqItem> _items = [];
  StreamSubscription? _faqSubscription;

  /// Creates a user faq view model instance.
  UserFaqViewModel({required GetUserFaqItemsUseCase getUserFaqItemsUseCase})
    : _getUserFaqItemsUseCase = getUserFaqItemsUseCase {
    watchItems();
  }

  // Getters
  bool get isLoading => _isLoading;

  /// Handles the error message operation.
  String? get errorMessage => _errorMessage;

  /// Handles the items operation.
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

  void watchItems() {
    _isLoading = true;
    notifyListeners();
    _faqSubscription?.cancel();
    _faqSubscription = _getUserFaqItemsUseCase.watch().listen((result) {
      if (result.isLeft()) {
        _errorMessage = _getErrorMessage(result.left!);
        _items = [];
      } else {
        _items = result.right!;
        _errorMessage = null;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _faqSubscription?.cancel();
    super.dispose();
  }

  /// Handles the get error message operation.
  String _getErrorMessage(Failure failure) {
    if (failure is NetworkFailure) {
      return 'Network error. Please check your connection.';
    }
    return failure.message;
  }
}
