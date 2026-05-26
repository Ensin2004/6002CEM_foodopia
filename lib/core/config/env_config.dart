// Defines the env config module.
// ENVIRONMENT CONFIGURATION
// ============================================================================
// Centralized configuration for the app
// For production, use environment variables or a secure backend
// ============================================================================

class EnvConfig {
  // Cloudinary Configuration
  static const String cloudinaryCloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
  );
  static const String userProfileUploadPreset = String.fromEnvironment(
    'CLOUDINARY_USER_PROFILE_UPLOAD_PRESET',
  );
  static const String settingsUploadPreset = String.fromEnvironment(
    'CLOUDINARY_SETTINGS_UPLOAD_PRESET',
  );
  static const String recipeUploadPreset = String.fromEnvironment(
    'CLOUDINARY_RECIPE_UPLOAD_PRESET',
  );
  static const String ingredientUploadPreset = String.fromEnvironment(
    'CLOUDINARY_INGREDIENT_UPLOAD_PRESET',
  );
  static const String instructionUploadPreset = String.fromEnvironment(
    'CLOUDINARY_INSTRUCTION_UPLOAD_PRESET',
  );
  static const String usdaApiKey = String.fromEnvironment('USDA_API_KEY');
  static const String openAiApiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const String openAiRecipeModel = String.fromEnvironment(
    'OPENAI_RECIPE_MODEL',
    defaultValue: 'gpt-4o-mini',
  );
  static const String openAiIngredientModel = String.fromEnvironment(
    'OPENAI_INGREDIENT_MODEL',
    defaultValue: 'gpt-4o-mini',
  );
  static const String openAiImageModel = String.fromEnvironment(
    'OPENAI_IMAGE_MODEL',
    defaultValue: 'gpt-image-2',
  );

  // Firebase Configuration (already in the google-services.json)
  // No need to duplicate here

  // API Endpoints
  // static const String baseUrl = 'https://api.xxx.com';
}
