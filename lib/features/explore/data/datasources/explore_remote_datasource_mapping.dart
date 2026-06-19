part of 'explore_remote_datasource.dart';

extension ExploreRemoteDataSourceMapping on ExploreRemoteDataSource {
  // Fetches all public recipes created by a specific user, sorted by most recent update or creation.
  Future<List<ExploreRecipeModel>> _getCreatorRecipes(String creatorUid) async {
    // Attempt query using 'creatorId' field first.
    var snapshot = await firestore
        .collection('recipes')
        .where('creatorId', isEqualTo: creatorUid)
        .get();
    // Fallback to 'creatorUid' if no results found.
    if (snapshot.docs.isEmpty) {
      snapshot = await firestore
          .collection('recipes')
          .where('creatorUid', isEqualTo: creatorUid)
          .get();
    }

    // Filter for public finalized recipes and sort by date descending.
    final docs =
    snapshot.docs.where((doc) {
      return _isPublicFinalizedRecipe(doc.data());
    }).toList()..sort((first, second) {
      final firstData = first.data();
      final secondData = second.data();
      final firstDate = _dateTime(
        firstData['updatedAt'] ?? firstData['createdAt'],
      );
      final secondDate = _dateTime(
        secondData['updatedAt'] ?? secondData['createdAt'],
      );
      return secondDate.compareTo(firstDate);
    });

    // Build recipe models sequentially.
    final recipes = <ExploreRecipeModel>[];
    for (final doc in docs) {
      recipes.add(await _recipeFromDoc(doc, includeCommunity: false));
    }
    return recipes;
  }

  // Constructs a complete recipe model from a Firestore document snapshot.
  Future<ExploreRecipeModel> _recipeFromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc, {
        required bool includeCommunity,
      }) async {
    final data = doc.data() ?? {};
    // Determine creator UID from either field.
    final creatorUid = _stringValue(data['creatorId']).isNotEmpty
        ? _stringValue(data['creatorId'])
        : _stringValue(data['creatorUid']);
    final currentUid = auth.currentUser?.uid ?? '';
    final isCurrentUserCreator =
        creatorUid.isNotEmpty && creatorUid == currentUid;
    // Fetch social and relational data in parallel.
    final isFollowingAuthor = await _isFollowingCreator(creatorUid);
    final isFavourite = await _isFavouriteRecipe(doc.id);
    final creator = await _getCreator(creatorUid);
    // Resolve category and allergen names from configuration and custom collections.
    final categoryIds = _stringList(data['categoryIds']);
    final customCategoryIds = _stringList(data['customCategoryIds']);
    final categoryNames = await _resolveOptionNames(
      configId: 'recipe_categories',
      ids: categoryIds,
      customCollectionId: 'custom_categories',
      customIds: customCategoryIds,
    );
    final allergenNames = await _resolveOptionNames(
      configId: 'allergies',
      ids: _stringList(data['allergenIds']),
      customCollectionId: 'custom_allergens',
      customIds: _stringList(data['customAllergenIds']),
    );
    final media = _stringList(data['media']);
    final nutrition = _nutritionFromData(data['totalNutrients']);
    // Fetch ingredients with calorie context.
    final ingredients = await _getIngredients(
      doc.reference,
      totalCalories: nutrition.calories,
    );
    final ingredientNames = ingredients
        .map((ingredient) => ingredient.name)
        .toList();
    // Conditionally fetch community data for detailed views.
    final instructions = includeCommunity
        ? await _getInstructionSections(doc.reference)
        : const <ExploreInstructionSection>[];
    final community = includeCommunity
        ? await _getCommunity(doc.reference, creator.name)
        : const ExploreCommunity(
      authorBio: '',
      ratingBreakdown: [],
      reviews: [],
      comments: [],
    );
    final relatedRecipes = includeCommunity
        ? await _getRelatedRecipes(
      creatorUid: creatorUid,
      currentRecipeId: doc.id,
    )
        : const <ExploreRecipeSummary>[];
    // Check if current user has rated this recipe.
    final hasRatedByCurrentUser = includeCommunity && currentUid.isNotEmpty
        ? (await doc.reference.collection('ratings').doc(currentUid).get())
        .exists
        : false;
    final ratingCount = _intValue(data['ratingCount']);
    final publishedAt = _dateTime(data['updatedAt'] ?? data['createdAt']);

    // Assemble and return the complete recipe model.
    return ExploreRecipeModel(
      id: doc.id,
      creatorUid: creatorUid,
      title: _stringValue(data['name'], fallback: 'Untitled Recipe'),
      author: isCurrentUserCreator ? 'You' : creator.name,
      publishedAtLabel: _dateLabel(publishedAt),
      authorAvatarPath: creator.profileImage,
      authorFollowerCount: creator.followerCount,
      imagePath: media.isNotEmpty
          ? media.first
          : 'assets/images/empty_page.png',
      imagePaths: media,
      description: _stringValue(data['description']),
      otherNames: _stringList(data['otherNames']),
      category: categoryNames.isEmpty
          ? 'Uncategorised'
          : categoryNames.join(', '),
      categoryIds: categoryIds,
      customCategoryIds: customCategoryIds,
      tags: _stringList(data['tags']),
      ingredientNames: ingredientNames,
      allergenInfo: allergenNames.isEmpty
          ? 'No allergens listed'
          : allergenNames.join(', '),
      totalTime: '${_intValue(data['preparationTime'])} min',
      difficulty: _difficultyLabel(data['difficultyLevel']),
      servings: _intValue(data['servings']).clamp(1, 999),
      rating: _doubleValue(data['averageRating']),
      ratingCount: ratingCount,
      commentCount: _intValue(data['commentCount']),
      totalViews: _intValue(data['totalViews']),
      publishedAt: publishedAt,
      isFollowingAuthor: isFollowingAuthor,
      isFavourite: isFavourite,
      isCreatedByCurrentUser: isCurrentUserCreator,
      hasRatedByCurrentUser: hasRatedByCurrentUser,
      ingredients: ingredients,
      instructionSections: instructions,
      nutrition: nutrition,
      community: community,
      relatedRecipes: relatedRecipes,
    );
  }

  // Parses nutrition data from Firestore map into a structured nutrition object.
  ExploreNutrition _nutritionFromData(dynamic value) {
    final nutrients = value is Map ? value : const {};
    return ExploreNutrition(
      calories: _numericValue(nutrients['calories'])?.round() ?? 0,
      proteinGrams: _numericValue(nutrients['protein'])?.round() ?? 0,
      carbsGrams: _numericValue(nutrients['carbohydrates'])?.round() ?? 0,
      fatGrams: _numericValue(nutrients['fat'])?.round() ?? 0,
      fiberGrams: _numericValue(nutrients['fiber'])?.round() ?? 0,
      waterGrams: _numericValue(nutrients['water'])?.round() ?? 0,
      vitamins: _nutrientAmountsFromData(nutrients, _vitaminDefinitions),
      minerals: _nutrientAmountsFromData(nutrients, _mineralDefinitions),
    );
  }

  // Converts raw nutrient data into a list of nutrient amounts based on provided definitions.
  List<ExploreNutrientAmount> _nutrientAmountsFromData(
      Map<dynamic, dynamic> nutrients,
      List<_NutrientDefinition> definitions,
      ) {
    return definitions
        .map((definition) {
      final amount = _numericValue(nutrients[definition.key]);
      // Skip nutrients with no positive amount.
      if (amount == null || amount <= 0) return null;
      return ExploreNutrientAmount(
        key: definition.key,
        label: definition.label,
        amount: amount,
        unit: definition.unit,
        dailyValue: definition.dailyValue,
      );
    })
        .whereType<ExploreNutrientAmount>()
        .toList(growable: false);
  }

  // Retrieves up to 4 related recipes from the same creator, excluding the current recipe.
  Future<List<ExploreRecipeSummary>> _getRelatedRecipes({
    required String creatorUid,
    required String currentRecipeId,
  }) async {
    if (creatorUid.isEmpty) return const [];

    // Query recipes by creator using either field.
    var snapshot = await firestore
        .collection('recipes')
        .where('creatorId', isEqualTo: creatorUid)
        .get();
    if (snapshot.docs.isEmpty) {
      snapshot = await firestore
          .collection('recipes')
          .where('creatorUid', isEqualTo: creatorUid)
          .get();
    }

    // Filter out current recipe and non-public ones, then sort by date.
    final docs =
    snapshot.docs.where((doc) {
      final data = doc.data();
      return doc.id != currentRecipeId && _isPublicFinalizedRecipe(data);
    }).toList()..sort((first, second) {
      final firstData = first.data();
      final secondData = second.data();
      final firstDate = _dateTime(
        firstData['updatedAt'] ?? firstData['createdAt'],
      );
      final secondDate = _dateTime(
        secondData['updatedAt'] ?? secondData['createdAt'],
      );
      return secondDate.compareTo(firstDate);
    });

    // Take top 4 and map to summary objects.
    return docs.take(4).map((doc) {
      final data = doc.data();
      final media = _stringList(data['media']);
      return ExploreRecipeSummary(
        id: doc.id,
        title: _stringValue(data['name'], fallback: 'Untitled Recipe'),
        imagePath: media.isNotEmpty
            ? media.first
            : 'assets/images/empty_page.png',
      );
    }).toList();
  }

  // Fetches creator profile information from the users collection.
  Future<_CreatorProfile> _getCreator(String creatorUid) async {
    if (creatorUid.isEmpty) {
      return const _CreatorProfile(name: 'Unknown Creator', profileImage: '');
    }

    final doc = await firestore.collection('users').doc(creatorUid).get();
    final data = doc.data() ?? {};
    return _CreatorProfile(
      name: _stringValue(data['name'], fallback: 'Unknown Creator'),
      profileImage: _stringValue(data['profileImage']),
      followerCount: _intValue(data['followerCount']),
    );
  }

  // Checks if the current user follows a given creator.
  Future<bool> _isFollowingCreator(String creatorUid) async {
    final uid = auth.currentUser?.uid ?? '';
    // Skip check for self or missing data.
    if (uid.isEmpty || creatorUid.isEmpty || uid == creatorUid) return false;
    final doc = await firestore
        .collection('users')
        .doc(uid)
        .collection('followingCreators')
        .doc(creatorUid)
        .get();
    return doc.exists;
  }

  // Checks if the current user has saved a recipe as favourite.
  Future<bool> _isFavouriteRecipe(String recipeId) async {
    final uid = auth.currentUser?.uid ?? '';
    if (uid.isEmpty || recipeId.isEmpty) return false;
    final doc = await firestore
        .collection('users')
        .doc(uid)
        .collection('saved_recipes')
        .doc(recipeId)
        .get();
    return doc.exists;
  }

  // Resolves option names from both system config and custom collections by ID.
  Future<List<String>> _resolveOptionNames({
    required String configId,
    required List<String> ids,
    required String customCollectionId,
    required List<String> customIds,
  }) async {
    final names = <String>[];

    // Fetch names from system configuration items.
    for (final id in ids) {
      final doc = await firestore
          .collection('app_config')
          .doc(configId)
          .collection('items')
          .doc(id)
          .get();
      names.add(_stringValue(doc.data()?['name'], fallback: id));
    }

    // Fetch names from custom items.
    for (final id in customIds) {
      final doc = await firestore
          .collection('custom')
          .doc(customCollectionId)
          .collection('items')
          .doc(id)
          .get();
      names.add(_stringValue(doc.data()?['name'], fallback: id));
    }

    // Return only non-empty names.
    return names.where((name) => name.trim().isNotEmpty).toList();
  }
}