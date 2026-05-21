import '../models/explore_recipe_model.dart';
import '../../domain/entities/explore_recipe.dart';

class ExploreMockDataSource {
  Future<List<ExploreRecipeModel>> getRecipes() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return _recipes;
  }

  Future<ExploreRecipeModel> getRecipeDetail(String recipeId) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return _recipes.firstWhere(
      (recipe) => recipe.id == recipeId,
      orElse: () => throw StateError('Recipe not found'),
    );
  }
}

const _avatar = 'assets/images/onboarding1.png';
const _stepImage = 'assets/images/meal3(2).png';

const _defaultIngredients = [
  ExploreIngredient(
    name: 'Eggs',
    amount: '1 unit',
    calories: '72 kcal',
    imagePath: 'assets/images/meal1.png',
    nutritionPercent: 0.18,
  ),
  ExploreIngredient(
    name: 'Avocado',
    amount: '1 slice',
    calories: '120 kcal',
    imagePath: 'assets/images/meal2.png',
    nutritionPercent: 0.32,
  ),
  ExploreIngredient(
    name: 'Sourdough Bread',
    amount: '2 slices',
    calories: '110 kcal',
    imagePath: 'assets/images/meal3.png',
    nutritionPercent: 0.27,
  ),
  ExploreIngredient(
    name: 'Garlic Spread',
    amount: '1 tbsp',
    calories: '100 kcal',
    imagePath: 'assets/images/meal3(2).png',
    nutritionPercent: 0.23,
  ),
];

const _defaultInstructionSections = [
  ExploreInstructionSection(
    title: 'Making The Sunny Side Up',
    steps: [
      ExploreInstructionStep(
        title: 'Step 1',
        imagePath: _stepImage,
        description:
            'Warm a little oil in a non-stick pan, then crack the egg in gently and cook until the white is set.',
      ),
      ExploreInstructionStep(
        title: 'Step 2',
        imagePath: _stepImage,
        description:
            'Season with salt and pepper. Keep the yolk soft for a creamy finish.',
      ),
    ],
  ),
  ExploreInstructionSection(
    title: 'Making The Avocado Toast',
    steps: [
      ExploreInstructionStep(
        title: 'Step 1',
        imagePath: _stepImage,
        description:
            'Toast the sourdough, spread the garlic mix, and layer sliced avocado over the top.',
      ),
      ExploreInstructionStep(
        title: 'Step 2',
        imagePath: _stepImage,
        description:
            'Place the egg over the avocado and finish with herbs or chili flakes.',
      ),
    ],
  ),
];

const _defaultNutrition = ExploreNutrition(
  calories: 402,
  carbsGrams: 33,
  proteinGrams: 28,
  fatGrams: 17,
);

final _defaultCommunity = ExploreCommunity(
  authorBio: 'Hi, I am the author and recipe creator behind this meal.',
  ratingBreakdown: const [
    ExploreRatingBreakdown(stars: 5, count: 110),
    ExploreRatingBreakdown(stars: 4, count: 12),
    ExploreRatingBreakdown(stars: 3, count: 4),
    ExploreRatingBreakdown(stars: 2, count: 1),
    ExploreRatingBreakdown(stars: 1, count: 1),
  ],
  reviews: [
    ExploreReview(
      author: 'Amir Arif',
      avatarPath: _avatar,
      timeAgo: '2 min ago',
      createdAt: DateTime(2026, 5, 19, 8, 58),
      rating: 4,
    ),
    ExploreReview(
      author: 'Emma Johnson',
      avatarPath: _avatar,
      timeAgo: '18 min ago',
      createdAt: DateTime(2026, 5, 19, 8, 42),
      rating: 5,
    ),
    ExploreReview(
      author: 'Sophia Lee',
      avatarPath: _avatar,
      timeAgo: '47 min ago',
      createdAt: DateTime(2026, 5, 19, 8, 13),
      rating: 5,
    ),
    ExploreReview(
      author: 'Jeffrey Epstein',
      avatarPath: _avatar,
      timeAgo: '1 hr ago',
      createdAt: DateTime(2026, 5, 19, 8),
      rating: 5,
    ),
    ExploreReview(
      author: 'Briyani',
      avatarPath: _avatar,
      timeAgo: '2 hrs ago',
      createdAt: DateTime(2026, 5, 19, 7),
      rating: 5,
    ),
  ],
  comments: [
    ExploreComment(
      id: 'mock-comment-1',
      author: 'You',
      avatarPath: _avatar,
      timeAgo: '2 min ago',
      createdAt: DateTime(2026, 5, 19, 8, 58),
      content:
          'I burnt the toast but decided to blame this recipe instead. Definitely not my problem.',
      likes: 128,
      replies: [
        ExploreCommentReply(
          id: 'mock-reply-1',
          documentPath:
              'recipes/sunny-egg-toast/comments/mock-comment-1/replies/mock-reply-1',
          author: 'Alex Fala',
          avatarPath: _avatar,
          timeAgo: '1 min ago',
          createdAt: DateTime(2026, 5, 19, 8, 59),
          content: 'A little lower heat helps a lot.',
          likes: 4,
        ),
      ],
    ),
    ExploreComment(
      id: 'mock-comment-2',
      author: 'Emma Johnson',
      avatarPath: _avatar,
      timeAgo: '18 min ago',
      createdAt: DateTime(2026, 5, 19, 8, 42),
      content: 'Absolutely delicious and easy to make! My go-to breakfast now.',
      likes: 67,
    ),
    ExploreComment(
      id: 'mock-comment-3',
      author: 'Sophia Lee',
      avatarPath: _avatar,
      timeAgo: '47 min ago',
      createdAt: DateTime(2026, 5, 19, 8, 13),
      content:
          'Great recipe for a simple morning. Absolutely love this recipe.',
      likes: 56,
    ),
    ExploreComment(
      id: 'mock-comment-4',
      author: 'Jeffrey Epstein',
      avatarPath: _avatar,
      timeAgo: '1 hr ago',
      createdAt: DateTime(2026, 5, 19, 8),
      content:
          'I loved me some raw avocado in the morning. Especially eating them with kids.',
      likes: 999,
    ),
  ],
);

final _recipes = <ExploreRecipeModel>[
  ExploreRecipeModel(
    id: 'sunny-egg-toast',
    creatorUid: 'mock-creator',
    title: 'Sunny Egg & Toast Avocado',
    author: 'Alex Fala',
    publishedAtLabel: '2hrs Ago',
    authorAvatarPath: _avatar,
    imagePath: 'assets/images/meal1.png',
    imagePaths: const [
      'assets/images/meal1.png',
      'assets/images/meal2.png',
      'assets/images/meal3.png',
    ],
    description:
        'Crispy sourdough layered with savory garlic spread and fanned avocado, served with a sunny-side-up egg. A simple, flavor-packed meal that is high in protein and healthy fats.',
    otherNames: const ['Avocado Egg Toast'],
    category: 'Breakfast, Healthy, Bread',
    categoryIds: const ['breakfast', 'healthy', 'bread'],
    allergenInfo: 'Gluten, dairy',
    totalTime: '15 min',
    difficulty: 'Easy',
    rating: 4.9,
    ratingCount: 128,
    commentCount: 4,
    totalViews: 1500,
    publishedAt: DateTime(2026, 5, 19, 9),
    isFollowingAuthor: false,
    isCreatedByCurrentUser: false,
    ingredients: _defaultIngredients,
    instructionSections: _defaultInstructionSections,
    nutrition: _defaultNutrition,
    community: _defaultCommunity,
    relatedRecipes: const [
      ExploreRecipeSummary(
        id: 'tomato-ravioli',
        title: 'Tomato Ravioli',
        imagePath: 'assets/images/meal2.png',
      ),
      ExploreRecipeSummary(
        id: 'bowl-of-rice',
        title: 'Bowl of Rice',
        imagePath: 'assets/images/meal3.png',
      ),
      ExploreRecipeSummary(
        id: 'chicken-skillet',
        title: 'Chicken Skillet',
        imagePath: 'assets/images/meal3(2).png',
      ),
    ],
  ),
  _simpleRecipe(
    id: 'easy-burger',
    title: 'Easy Homemade Burger',
    imagePath: 'assets/images/meal2.png',
    imagePaths: const ['assets/images/meal2.png', 'assets/images/meal3.png'],
    category: 'Lunch, Bread',
    rating: 4.1,
    publishedAtLabel: 'Yesterday',
    isFollowing: false,
  ),
  _simpleRecipe(
    id: 'mushroom-soup',
    title: 'Mushroom Soup with Garlic Bread',
    imagePath: 'assets/images/meal3.png',
    imagePaths: const ['assets/images/meal3.png'],
    category: 'Dinner, Soup',
    rating: 4.5,
    publishedAtLabel: '25 Apr 2026',
    isFollowing: false,
  ),
  _simpleRecipe(
    id: 'classic-pesto',
    title: 'Classic Italian Basil Pesto Pasta',
    imagePath: 'assets/images/meal3(2).png',
    imagePaths: const ['assets/images/meal3(2).png', 'assets/images/meal1.png'],
    category: 'Pasta, Italian',
    rating: 3.2,
    publishedAtLabel: '14 Mar 2026',
    isFollowing: false,
  ),
  _simpleRecipe(
    id: 'berry-yogurt-bowl',
    title: 'Berry Yogurt Breakfast Bowl',
    imagePath: 'assets/images/meal1.png',
    imagePaths: const ['assets/images/meal1.png'],
    category: 'Breakfast, Fruit',
    rating: 4.7,
    publishedAtLabel: '8 May 2026',
    isFollowing: false,
  ),
  _simpleRecipe(
    id: 'grilled-chicken-salad',
    title: 'Grilled Chicken Garden Salad',
    imagePath: 'assets/images/meal2.png',
    imagePaths: const ['assets/images/meal2.png', 'assets/images/meal3(2).png'],
    category: 'Lunch, Salad',
    rating: 4.4,
    publishedAtLabel: '1 May 2026',
    isFollowing: false,
  ),
];

ExploreRecipeModel _simpleRecipe({
  required String id,
  required String title,
  required String imagePath,
  required List<String> imagePaths,
  required String category,
  required double rating,
  required String publishedAtLabel,
  required bool isFollowing,
}) {
  return ExploreRecipeModel(
    id: id,
    creatorUid: 'mock-creator',
    title: title,
    author: 'Alex Fala',
    publishedAtLabel: publishedAtLabel,
    authorAvatarPath: _avatar,
    imagePath: imagePath,
    imagePaths: imagePaths,
    description:
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. A balanced meal for everyday cooking.',
    otherNames: const [],
    category: category,
    categoryIds: category.split(',').map((item) => item.trim()).toList(),
    allergenInfo: 'Check ingredients before cooking',
    totalTime: '20 min',
    difficulty: 'Easy',
    rating: rating,
    ratingCount: 80,
    commentCount: 12,
    totalViews: 320,
    publishedAt: DateTime(2026, 5, 19, 8),
    isFollowingAuthor: isFollowing,
    isCreatedByCurrentUser: false,
    ingredients: _defaultIngredients,
    instructionSections: _defaultInstructionSections,
    nutrition: _defaultNutrition,
    community: _defaultCommunity,
    relatedRecipes: const [],
  );
}
