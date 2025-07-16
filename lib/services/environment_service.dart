import 'package:flutter/foundation.dart';

class EnvironmentService {
  static final EnvironmentService _instance = EnvironmentService._internal();
  factory EnvironmentService() => _instance;
  EnvironmentService._internal();

  // Environment configuration
  static const String _environment =
      String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
  static const bool _enableMockOTP =
      bool.fromEnvironment('ENABLE_MOCK_OTP', defaultValue: true);
  static const String _mockOTPCode =
      String.fromEnvironment('MOCK_OTP_CODE', defaultValue: '123456');

  // Environment getters
  bool get isDevelopment => _environment == 'development';
  bool get isProduction => _environment == 'production';
  bool get isStaging => _environment == 'staging';

  bool get enableMockOTP => _enableMockOTP && !isProduction;
  String get mockOTPCode => _mockOTPCode;

  // Supabase configuration
  static const String supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  // Twilio configuration
  static const String twilioAccountSid =
      String.fromEnvironment('TWILIO_ACCOUNT_SID', defaultValue: '');
  static const String twilioAuthToken =
      String.fromEnvironment('TWILIO_AUTH_TOKEN', defaultValue: '');
  static const String twilioMessagingServiceSid =
      String.fromEnvironment('TWILIO_MESSAGING_SERVICE_SID', defaultValue: '');
  static const String twilioWhatsappNumber =
      String.fromEnvironment('TWILIO_WHATSAPP_NUMBER', defaultValue: '');

  // Configuration validation
  bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  bool get isTwilioConfigured =>
      twilioAccountSid.isNotEmpty && twilioAuthToken.isNotEmpty;
  bool get isWhatsappConfigured =>
      isTwilioConfigured && twilioWhatsappNumber.isNotEmpty;

  // Get comprehensive configuration status
  Map<String, dynamic> getConfigurationStatus() {
    return {
      'environment': _environment,
      'is_production': isProduction,
      'mock_otp_enabled': enableMockOTP,
      'supabase_configured': isSupabaseConfigured,
      'twilio_sms_configured': isTwilioConfigured,
      'twilio_whatsapp_configured': isWhatsappConfigured,
      'all_services_ready': isSupabaseConfigured && isTwilioConfigured,
    };
  }

  // Development mode helpers
  void logConfiguration() {
    if (kDebugMode) {
      final config = getConfigurationStatus();
      debugPrint('=== Lucky Rascals Configuration ===');
      config.forEach((key, value) {
        debugPrint('$key: $value');
      });
      debugPrint('====================================');
    }
  }

  // Production readiness check
  bool isProductionReady() {
    return isSupabaseConfigured &&
        isTwilioConfigured &&
        isWhatsappConfigured &&
        !enableMockOTP;
  }

  String getProductionReadinessReport() {
    final issues = <String>[];

    if (!isSupabaseConfigured) issues.add('Supabase not configured');
    if (!isTwilioConfigured) issues.add('Twilio SMS not configured');
    if (!isWhatsappConfigured) issues.add('Twilio WhatsApp not configured');
    if (enableMockOTP) issues.add('Mock OTP still enabled');

    return issues.isEmpty
        ? 'All systems ready for production'
        : 'Issues: ${issues.join(', ')}';
  }
}
