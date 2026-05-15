import 'package:flutter/foundation.dart';

enum AddRecipeMethod {
  uploadVideo,
  scratch,
}

class AddRecipeMethodViewModel extends ChangeNotifier {
  AddRecipeMethod? _selectedMethod;

  AddRecipeMethod? get selectedMethod => _selectedMethod;

  void selectMethod(AddRecipeMethod method) {
    _selectedMethod = method;
    notifyListeners();
  }
}

