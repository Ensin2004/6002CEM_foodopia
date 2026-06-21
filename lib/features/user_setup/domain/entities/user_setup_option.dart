/// Represents an option in the user setup flow.
/// Used for diet, allergies, dislikes, and other preference selections.
class UserSetupOption {
  /// Unique identifier of the option.
  final String id;

  /// Display name of the option.
  final String name;

  /// Whether this is a custom option added by the user.
  final bool isCustom;

  /// Creates a new user setup option instance.
  const UserSetupOption({
    required this.id,
    required this.name,
    this.isCustom = false,
  });
}