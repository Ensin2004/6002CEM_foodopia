import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/extensions/either_extensions.dart';
import '../../../domain/entities/about_content.dart';
import '../../../domain/usecases/about/get_about_content_usecase.dart';

/// Defines behavior for about viewer view model.
class AboutViewerViewModel extends ChangeNotifier {
  final GetAboutContentUseCase _getAboutContentUseCase;
  final String _documentId;
  final String _title;

  // State
  bool _isLoading = true;
  String? _errorMessage;
  AboutContent? _content;
  StreamSubscription? _contentSubscription;

  /// Creates a about viewer view model instance.
  AboutViewerViewModel({
    required String documentId,
    required String title,
    required GetAboutContentUseCase getAboutContentUseCase,
  }) : _documentId = documentId,
       _title = title,
       _getAboutContentUseCase = getAboutContentUseCase {
    watchContent();
  }

  // Getters
  bool get isLoading => _isLoading;

  /// Handles the error message operation.
  String? get errorMessage => _errorMessage;

  /// Handles the content operation.
  AboutContent? get content => _content;

  /// Handles the title operation.
  String get title => _title;

  // Getter to check if content is empty
  bool get hasContent => _content?.content.isNotEmpty ?? false;

  // Load content
  Future<void> loadContent() async {
    _isLoading = true;
    notifyListeners();

    final result = await _getAboutContentUseCase.execute(_documentId);

    if (result.isLeft()) {
      // Uses left! instead of left (non-nullable)
      final failure = result.left!;

      // If document not found, that's okay - just show empty content
      if (failure is NotFoundFailure) {
        _content = AboutContent(
          id: _documentId,
          title: _title,
          content: '',
          updatedAt: null,
        );
        _errorMessage = null;
      } else {
        _errorMessage = _getErrorMessage(failure);
      }
      _isLoading = false;
      notifyListeners();
    } else {
      _content = result.right;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  void watchContent() {
    _isLoading = true;
    notifyListeners();
    _contentSubscription?.cancel();
    _contentSubscription = _getAboutContentUseCase.watch(_documentId).listen((
      result,
    ) {
      if (result.isLeft()) {
        _errorMessage = _getErrorMessage(result.left!);
      } else {
        _content = result.right;
        _errorMessage = null;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _contentSubscription?.cancel();
    super.dispose();
  }

  /// Handles the get error message operation.
  String _getErrorMessage(Failure failure) {
    if (failure is NotFoundFailure) {
      return 'Content not found';
    }
    if (failure is NetworkFailure) {
      return 'Network error. Please check your connection.';
    }
    return failure.message;
  }
}
