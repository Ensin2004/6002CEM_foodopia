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
  static const String usdaApiKey = String.fromEnvironment('USDA_API_KEY');

  // Firebase Configuration (already in the google-services.json)
  // No need to duplicate here

  // API Endpoints
  // static const String baseUrl = 'https://api.xxx.com';
}
