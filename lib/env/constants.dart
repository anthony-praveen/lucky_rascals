/// Constants for Lucky Rascals application
/// This file contains centralized configuration constants for better maintainability
class AppConstants {
  // Mock OTP Configuration
  static const bool ENABLE_MOCK_OTP = true; // Set to false for production
  static const String MOCK_OTP = '123456';

  // Application Configuration
  static const String APP_NAME = 'Lucky Rascals';
  static const String APP_VERSION = '1.0.0';

  // Phone Number Validation
  static const int MIN_PHONE_LENGTH = 10;
  static const int MAX_PHONE_LENGTH = 13;
  static const String COUNTRY_CODE = '+91';

  // UI Constants
  static const String MOCK_MODE_WARNING = '⚠️ Mock OTP Mode Enabled';
  static const String MOCK_MODE_DESCRIPTION = 'Development mode active';

  // OTP Configuration
  static const int OTP_LENGTH = 6;
  static const int OTP_EXPIRY_MINUTES = 10;

  // Error Messages
  static const String INVALID_PHONE_ERROR =
      'Please enter a valid mobile number';
  static const String NETWORK_ERROR = 'Network error. Please try again.';

  // Success Messages
  static const String OTP_SENT_SUCCESS = 'OTP sent successfully';
  static const String OTP_VERIFIED_SUCCESS = 'OTP verified successfully';

  // Private constructor to prevent instantiation
  AppConstants._();
}
