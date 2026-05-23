import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/add_recipe_review.dart';
import '../../domain/usecases/get_add_recipe_review_usecase.dart';

class AddRecipeReviewViewModel extends ChangeNotifier {
  final GetAddRecipeReviewUseCase getReviewUseCase;

  AddRecipeReview? review;
  bool isLoading = true;
  String? errorMessage;

  AddRecipeReviewViewModel({required this.getReviewUseCase});

  Future<void> loadReview(String recipeId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await getReviewUseCase.execute(recipeId);
    if (result.isLeft()) {
      errorMessage = result.left?.message ?? 'Unable to load recipe review.';
      review = null;
    } else {
      review = result.right;
    }

    isLoading = false;
    notifyListeners();
  }
}
