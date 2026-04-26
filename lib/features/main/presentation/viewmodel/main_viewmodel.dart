import 'package:flutter/material.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/repositories/main_repository.dart';

class MainViewModel extends ChangeNotifier {
  final UserEntity user;
  final MainRepository _repository;

  int _selectedIndex = 0;
  String? _profileImageUrl;
  bool _isLoading = false;
  String? _errorMessage;

  MainViewModel({
    required this.user,
    required MainRepository repository,
  }) : _repository = repository {
    _loadUserProfile();
    _updateLastLogin();
  }

  // Getters
  int get selectedIndex => _selectedIndex;
  String? get profileImageUrl => _profileImageUrl;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAdmin => user.isAdmin;
  bool get isUser => user.isUser;

  // Navigation
  void onTabTapped(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  // Load profile image
  Future<void> _loadUserProfile() async {
    _isLoading = true;
    notifyListeners();

    final result = await _repository.getUserProfileImage(user.uid);

    result.fold(
          (failure) {
        _errorMessage = failure.message;
        _isLoading = false;
        notifyListeners();
      },
          (imageUrl) {
        _profileImageUrl = imageUrl;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // Refresh profile (called after returning from settings)
  Future<void> refreshProfile() async {
    await _loadUserProfile();
  }

  // Update last login timestamp
  Future<void> _updateLastLogin() async {
    await _repository.updateLastLogin(user.uid);
  }

  @override
  void dispose() {
    super.dispose();
  }
}