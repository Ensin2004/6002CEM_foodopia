// Defines the env config module.
// ENVIRONMENT CONFIGURATION
// ============================================================================
// Centralized configuration for the app
// For production, use environment variables or a secure backend
// ============================================================================

class EnvConfig {
  // Cloudinary Configuration
  static const String cloudinaryCloudName = 'djyfiqzzu';
  static const String userProfileUploadPreset = 'foodopia_profile';
  static const String settingsUploadPreset = 'foodopia_settings';

// Firebase Configuration (already in the google-services.json)
// No need to duplicate here

// API Endpoints
// static const String baseUrl = 'https://api.xxx.com';
}
