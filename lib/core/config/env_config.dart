// Defines the env config module.
// ENVIRONMENT CONFIGURATION
// ============================================================================
// Centralized configuration for the app
// For production, use environment variables or a secure backend
// ============================================================================

/// Environment configuration class.
/// Contains all environment-specific configuration values.
class EnvConfig {
  // =========================================================================
  // CLOUDINARY CONFIGURATION
  // =========================================================================

  /// Cloudinary cloud name for image uploads.
  static const String cloudinaryCloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
  );

  /// Cloudinary upload preset for user profile images.
  static const String userProfileUploadPreset = String.fromEnvironment(
    'CLOUDINARY_USER_PROFILE_UPLOAD_PRESET',
  );

  /// Cloudinary upload preset for settings images.
  static const String settingsUploadPreset = String.fromEnvironment(
    'CLOUDINARY_SETTINGS_UPLOAD_PRESET',
  );

  /// Cloudinary upload preset for recipe images.
  static const String recipeUploadPreset = String.fromEnvironment(
    'CLOUDINARY_RECIPE_UPLOAD_PRESET',
  );

  /// Cloudinary upload preset for ingredient images.
  static const String ingredientUploadPreset = String.fromEnvironment(
    'CLOUDINARY_INGREDIENT_UPLOAD_PRESET',
  );

  /// Cloudinary upload preset for instruction images.
  static const String instructionUploadPreset = String.fromEnvironment(
    'CLOUDINARY_INSTRUCTION_UPLOAD_PRESET',
  );

  // =========================================================================
  // API KEYS
  // =========================================================================

  /// USDA Food Data Central API key.
  static const String usdaApiKey = String.fromEnvironment('USDA_API_KEY');

  /// Unsplash access key.
  static const String unsplashAccessKey = String.fromEnvironment(
    'UNSPLASH_ACCESS_KEY',
  );

  /// OpenAI API key.
  static const String openAiApiKey = String.fromEnvironment('OPENAI_API_KEY');

  // =========================================================================
  // OPENAI MODEL CONFIGURATION
  // =========================================================================

  /// OpenAI model for recipe generation.
  static const String openAiRecipeModel = String.fromEnvironment(
    'OPENAI_RECIPE_MODEL',
    defaultValue: 'gpt-4o-mini',
  );

  /// OpenAI model for ingredient analysis.
  static const String openAiIngredientModel = String.fromEnvironment(
    'OPENAI_INGREDIENT_MODEL',
    defaultValue: 'gpt-4o-mini',
  );

  /// OpenAI model for video recipe processing.
  static const String openAiVideoRecipeModel = String.fromEnvironment(
    'OPENAI_VIDEO_RECIPE_MODEL',
    defaultValue: 'gpt-4o-mini',
  );

  /// OpenAI model for audio transcription.
  static const String openAiTranscriptionModel = String.fromEnvironment(
    'OPENAI_TRANSCRIPTION_MODEL',
    defaultValue: 'whisper-1',
  );

  /// OpenAI model for image generation.
  static const String openAiImageModel = String.fromEnvironment(
    'OPENAI_IMAGE_MODEL',
    defaultValue: 'gpt-image-2',
  );

  // =========================================================================
  // API ENDPOINTS
  // =========================================================================

  // static const String baseUrl = 'https://api.xxx.com';
}
