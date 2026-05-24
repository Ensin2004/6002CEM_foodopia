import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/library_profile.dart';
import '../../domain/usecases/get_library_followers_usecase.dart';
import '../../domain/usecases/get_library_following_usecase.dart';

class LibraryProfileUsersViewModel extends ChangeNotifier {
  final GetLibraryFollowersUseCase _getFollowersUseCase;
  final GetLibraryFollowingUseCase _getFollowingUseCase;
  final bool showFollowers;

  List<LibraryProfileUser> _users = const [];
  bool _isLoading = true;
  String? _errorMessage;

  LibraryProfileUsersViewModel({
    required GetLibraryFollowersUseCase getFollowersUseCase,
    required GetLibraryFollowingUseCase getFollowingUseCase,
    required this.showFollowers,
  }) : _getFollowersUseCase = getFollowersUseCase,
       _getFollowingUseCase = getFollowingUseCase {
    Future.microtask(loadUsers);
  }

  List<LibraryProfileUser> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = showFollowers
        ? await _getFollowersUseCase.execute()
        : await _getFollowingUseCase.execute();

    result.ifRight((users) {
      _users = users;
    });
    result.ifLeft((failure) {
      _errorMessage = failure.message;
    });

    _isLoading = false;
    notifyListeners();
  }
}
