import '../../features/auth/domain/entities/user_entity.dart';

/// Typed arguments for home route
class HomeArgs {
  final UserEntity user;
  final String role;

  const HomeArgs({
    required this.user,
    required this.role,
  });
}

/// Typed arguments for edit profile route
class EditProfileArgs {
  final String uid;

  const EditProfileArgs({required this.uid});
}

/// Typed arguments for about pages
class AboutArgs {
  final String documentId;
  final String title;
  final bool isAdmin;

  const AboutArgs({
    required this.documentId,
    required this.title,
    required this.isAdmin,
  });
}