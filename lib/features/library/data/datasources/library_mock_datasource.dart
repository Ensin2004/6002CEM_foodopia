import '../models/library_recipe_model.dart';
import '../../domain/entities/library_recipe.dart';

class LibraryMockDataSource {
  Future<List<LibraryRecipeModel>> getRecipes() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return _recipes;
  }
}

const _avatar = 'assets/images/onboarding1.png';
const _stepImage = 'assets/images/meal3(2).png';

const _defaultIngredients = [
  LibraryIngredient(
    name: 'Eggs',
    amount: '1 unit',
    calories: '72 kcal',
    imagePath: 'assets/images/meal1.png',
    nutritionPercent: 0.18,
  ),
  LibraryIngredient(
    name: 'Avocado',
    amount: '1 slice',
    calories: '120 kcal',
    imagePath: 'assets/images/meal2.png',
    nutritionPercent: 0.32,
  ),
  LibraryIngredient(
    name: 'Sourdough Bread',
    amount: '2 slices',
    calories: '110 kcal',
    imagePath: 'assets/images/meal3.png',
    nutritionPercent: 0.27,
  ),
  LibraryIngredient(
    name: 'Garlic Spread',
    amount: '1 tbsp',
    calories: '100 kcal',
    imagePath: 'assets/images/meal3(2).png',
    nutritionPercent: 0.23,
  ),
];

const _defaultInstructionSections = [
  LibraryInstructionSection(
    title: 'Making The Sunny Side Up',
    steps: [
      LibraryInstructionStep(
        title: 'Step 1',
        imagePath: _stepImage,
        description:
            'Warm a little oil in a non-stick pan, then crack the egg in gently and cook until the white is set.',
      ),
      LibraryInstructionStep(
        title: 'Step 2',
        imagePath: _stepImage,
        description:
            'Season with salt and pepper. Keep the yolk soft for a creamy finish.',
      ),
    ],
  ),
  LibraryInstructionSection(
    title: 'Making The Avocado Toast',
    steps: [
      LibraryInstructionStep(
        title: 'Step 1',
        imagePath: _stepImage,
        description:
            'Toast the sourdough, spread the garlic mix, and layer sliced avocado over the top.',
      ),
      LibraryInstructionStep(
        title: 'Step 2',
        imagePath: _stepImage,
        description:
            'Place the egg over the avocado and finish with herbs or chili flakes.',
      ),
    ],
  ),
];

const _defaultNutrition = LibraryNutrition(
  calories: 402,
  carbsGrams: 33,
  proteinGrams: 28,
  fatGrams: 17,
);

const _defaultCommunity = LibraryCommunity(
  authorBio: 'Hi, I am the author and recipe creator behind this meal.',
  ratingBreakdown: [
    LibraryRatingBreakdown(stars: 5, count: 110),
    LibraryRatingBreakdown(stars: 4, count: 12),
    LibraryRatingBreakdown(stars: 3, count: 4),
    LibraryRatingBreakdown(stars: 2, count: 1),
    LibraryRatingBreakdown(stars: 1, count: 1),
  ],
  reviews: [
    LibraryReview(
      author: 'Amir Arif',
      avatarPath: _avatar,
      timeAgo: '2 min ago',
      rating: 4,
    ),
    LibraryReview(
      author: 'Emma Johnson',
      avatarPath: _avatar,
      timeAgo: '18 min ago',
      rating: 5,
    ),
    LibraryReview(
      author: 'Sophia Lee',
      avatarPath: _avatar,
      timeAgo: '47 min ago',
      rating: 5,
    ),
  ],
  comments: [
    LibraryComment(
      author: 'You',
      avatarPath: _avatar,
      timeAgo: '2 min ago',
      content:
          'I burnt the toast but decided to blame this recipe instead. Definitely not my problem.',
      likes: 128,
    ),
    LibraryComment(
      author: 'Emma Johnson',
      avatarPath: _avatar,
      timeAgo: '18 min ago',
      content: 'Absolutely delicious and easy to make! My go-to breakfast now.',
      likes: 67,
    ),
  ],
);

final _recipes = <LibraryRecipeModel>[
  LibraryRecipeModel(
    id: 'sunny-egg-toast',
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
    category: 'Breakfast, Healthy, Bread',
    allergenInfo: 'Gluten, dairy',
    totalTime: '15 min',
    difficulty: 'Easy',
    rating: 4.9,
    ratingCount: 128,
    commentCount: 4,
    totalViews: 1840,
    isSelfPublished: true,
    isFollowingAuthor: true,
    isPublished: false,
    ingredients: _defaultIngredients,
    instructionSections: _defaultInstructionSections,
    nutrition: _defaultNutrition,
    community: _defaultCommunity,
    relatedRecipes: const [
      LibraryRecipeSummary(
        id: 'tomato-ravioli',
        title: 'Tomato Ravioli',
        imagePath: 'assets/images/meal2.png',
      ),
      LibraryRecipeSummary(
        id: 'bowl-of-rice',
        title: 'Bowl of Rice',
        imagePath: 'assets/images/meal3.png',
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
    isSelfPublished: true,
    isPublished: true,
    isFollowing: true,
  ),
  _simpleRecipe(
    id: 'mushroom-soup',
    title: 'Mushroom Soup with Garlic Bread',
    imagePath: 'assets/images/meal3.png',
    imagePaths: const ['assets/images/meal3.png'],
    category: 'Dinner, Soup',
    rating: 4.5,
    publishedAtLabel: '25 Apr 2026',
    isSelfPublished: false,
    isPublished: true,
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
    isSelfPublished: true,
    isPublished: false,
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
    isSelfPublished: false,
    isPublished: true,
    isFollowing: true,
  ),
  _simpleRecipe(
    id: 'grilled-chicken-salad',
    title: 'Grilled Chicken Garden Salad',
    imagePath: 'assets/images/meal2.png',
    imagePaths: const ['assets/images/meal2.png', 'assets/images/meal3(2).png'],
    category: 'Lunch, Salad',
    rating: 4.4,
    publishedAtLabel: '1 May 2026',
    isSelfPublished: false,
    isPublished: true,
    isFollowing: false,
  ),
];

LibraryRecipeModel _simpleRecipe({
  required String id,
  required String title,
  required String imagePath,
  required List<String> imagePaths,
  required String category,
  required double rating,
  required String publishedAtLabel,
  required bool isSelfPublished,
  required bool isPublished,
  required bool isFollowing,
}) {
  return LibraryRecipeModel(
    id: id,
    title: title,
    author: 'Alex Fala',
    publishedAtLabel: publishedAtLabel,
    authorAvatarPath: _avatar,
    imagePath: imagePath,
    imagePaths: imagePaths,
    description:
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. A balanced meal for everyday cooking.',
    category: category,
    allergenInfo: 'Check ingredients before cooking',
    totalTime: '20 min',
    difficulty: 'Easy',
    rating: rating,
    ratingCount: 80,
    commentCount: 12,
    totalViews: 320,
    isSelfPublished: isSelfPublished,
    isFollowingAuthor: isFollowing,
    isPublished: isPublished,
    ingredients: _defaultIngredients,
    instructionSections: _defaultInstructionSections,
    nutrition: _defaultNutrition,
    community: _defaultCommunity,
    relatedRecipes: const [],
  );
}
