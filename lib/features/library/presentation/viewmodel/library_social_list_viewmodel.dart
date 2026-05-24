import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/library_social_profile.dart';
import '../../domain/usecases/get_library_followers_usecase.dart';
import '../../domain/usecases/get_library_following_usecase.dart';

enum LibrarySocialListType { followers, following }

class LibrarySocialListViewModel extends ChangeNotifier {
  final GetLibraryFollowersUseCase _getFollowersUseCase;
  final GetLibraryFollowingUseCase _getFollowingUseCase;
  final LibrarySocialListType type;

  List<LibrarySocialProfile> _profiles = const [];
  bool _isLoading = true;
  bool _isDisposed = false;
  String? _errorMessage;

  LibrarySocialListViewModel({
    required GetLibraryFollowersUseCase getFollowersUseCase,
    required GetLibraryFollowingUseCase getFollowingUseCase,
    required this.type,
  }) : _getFollowersUseCase = getFollowersUseCase,
       _getFollowingUseCase = getFollowingUseCase {
    Future.microtask(loadProfiles);
  }

  List<LibrarySocialProfile> get profiles => _profiles;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get shouldShowEmpty =>
      !_isLoading && _errorMessage == null && _profiles.isEmpty;

  String get title {
    switch (type) {
      case LibrarySocialListType.followers:
        return 'Followers';
      case LibrarySocialListType.following:
        return 'Following';
    }
  }

  Future<void> loadProfiles() async {
    _isLoading = _profiles.isEmpty;
    _errorMessage = null;
    _notifyIfActive();

    final result = switch (type) {
      LibrarySocialListType.followers => await _getFollowersUseCase.execute(),
      LibrarySocialListType.following => await _getFollowingUseCase.execute(),
    };

    if (_isDisposed) return;
    result.ifRight((profiles) {
      _profiles = profiles;
    });
    result.ifLeft((failure) {
      _errorMessage = failure.message;
    });

    _isLoading = false;
    _notifyIfActive();
  }

  void _notifyIfActive() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
