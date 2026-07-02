/// Search result returned from USDA food lookup for ingredient matching.
class AddRecipeFoodSearchResult {
  final int fdcId;
  final String name;

  const AddRecipeFoodSearchResult({
    required this.fdcId,
    required this.name,
  });
}
