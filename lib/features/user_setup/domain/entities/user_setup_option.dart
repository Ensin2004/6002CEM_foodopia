class UserSetupOption {
  final String id;
  final String name;
  final bool isCustom;

  const UserSetupOption({
    required this.id,
    required this.name,
    this.isCustom = false,
  });
}
