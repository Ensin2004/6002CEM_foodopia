import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/library_profile.dart';
import '../../domain/usecases/get_library_followers_usecase.dart';
import '../../domain/usecases/get_library_following_usecase.dart';

// Manages loading state, errors, and profile connection results for followers and following pages.
class LibraryProfileUsersViewModel extends ChangeNotifier {
  final GetLibraryFollowersUseCase _getFollowersUseCase;
  final GetLibraryFollowingUseCase _getFollowingUseCase;
  final bool showFollowers;
  final String? ownerUid;

  List<LibraryProfileUser> _users = const [];
  bool _isLoading = true;
  String? _errorMessage;

  LibraryProfileUsersViewModel({
    required GetLibraryFollowersUseCase getFollowersUseCase,
    required GetLibraryFollowingUseCase getFollowingUseCase,
    required this.showFollowers,
    this.ownerUid,
  }) : _getFollowersUseCase = getFollowersUseCase,
       _getFollowingUseCase = getFollowingUseCase {
    // Starts loading the selected connection list after the view model is created.
    Future.microtask(loadUsers);
  }

  List<LibraryProfileUser> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadUsers() async {
    // Resets the screen state before requesting either followers or following profiles.
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Chooses the correct use case based on the current connection list mode.
    final result = showFollowers
        ? await _getFollowersUseCase.execute(ownerUid: ownerUid)
        : await _getFollowingUseCase.execute(ownerUid: ownerUid);

    // Stores successful profile results and keeps failure text for the UI error state.
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
