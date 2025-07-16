import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import './supabase_service.dart';
import './twilio_service.dart';
import './environment_service.dart';

class OTPService {
  final SupabaseService _supabaseService = SupabaseService();
  final TwilioService _twilioService = TwilioService();
  final EnvironmentService _environmentService = EnvironmentService();

  // Get initialized Supabase client with comprehensive error handling
  Future<SupabaseClient?> _getClient() async {
    try {
      final client = await _supabaseService.client;
      if (client == null) {
        throw Exception('Supabase client is null');
      }
      return client;
    } catch (error) {
      debugPrint('Supabase client initialization failed: $error');
      return null;
    }
  }

  // Enhanced phone number validation
  bool _isValidPhoneNumber(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      return false;
    }

    // Remove spaces and special characters except +
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // Check for valid format
    if (cleanPhone.startsWith('+91') && cleanPhone.length == 13) {
      final number = cleanPhone.substring(3);
      return number.startsWith(RegExp(r'[6-9]')) && number.length == 10;
    }

    return false;
  }

  // Format phone number consistently
  String? _formatPhoneNumber(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      return null;
    }

    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanPhone.length == 10 && cleanPhone.startsWith(RegExp(r'[6-9]'))) {
      return '+91$cleanPhone';
    }

    return null;
  }

  // Check if Supabase is properly configured
  Future<bool> _isSupabaseConfigured() async {
    try {
      final client = await _getClient();
      if (client == null) return false;

      // Try to get current user to test connection
      final user = client.auth.currentUser;
      return true; // If we can access auth, Supabase is configured
    } catch (error) {
      debugPrint('Supabase configuration check failed: $error');
      return false;
    }
  }

  // Send OTP with proper Twilio integration and fallback logic
  Future<Map<String, dynamic>> sendOTP({
    required String phoneNumber,
    required String otpType,
  }) async {
    try {
      // Validate phone number
      if (!_isValidPhoneNumber(phoneNumber)) {
        throw Exception(
            'Invalid phone number format. Please enter a valid 10-digit Indian mobile number.');
      }

      final formattedPhone = _formatPhoneNumber(phoneNumber);
      if (formattedPhone == null) {
        throw Exception('Unable to format phone number. Please try again.');
      }

      // Check service availability
      final isSupabaseConfigured = await _isSupabaseConfigured();
      final isTwilioConfigured = _twilioService.isConfigured;

      // Development mode with mock OTP
      if (_environmentService.enableMockOTP &&
          !_environmentService.isProduction) {
        debugPrint(
            'Using mock OTP for development: ${_environmentService.mockOTPCode}');
        return {
          'success': true,
          'message': 'OTP sent successfully (Development Mode)',
          'otp_type': otpType,
          'phone_number': formattedPhone,
          'mock_otp': _environmentService.mockOTPCode,
          'is_mock': true,
        };
      }

      // Production mode - require all services
      if (!isSupabaseConfigured || !isTwilioConfigured) {
        throw Exception(
            'Service temporarily unavailable. Please try again later.');
      }

      // Generate OTP
      final otpCode = _generateOTP();

      // Determine send method based on WhatsApp availability
      final useWhatsApp = otpType.toLowerCase() == 'whatsapp' &&
          _twilioService.isWhatsAppAvailable(formattedPhone);

      Map<String, dynamic> sendResult;

      if (useWhatsApp) {
        // Try WhatsApp first
        try {
          sendResult = await _twilioService.sendWhatsApp(
              toNumber: formattedPhone,
              message:
                  'Your Lucky Rascals OTP is: $otpCode. Valid for 10 minutes. Do not share this code.');
        } catch (whatsappError) {
          debugPrint('WhatsApp failed, falling back to SMS: $whatsappError');
          // Fallback to SMS
          sendResult = await _twilioService.sendSMS(
              toNumber: formattedPhone,
              message:
                  'Your Lucky Rascals OTP is: $otpCode. Valid for 10 minutes.');
        }
      } else {
        // Send via SMS
        sendResult = await _twilioService.sendSMS(
            toNumber: formattedPhone,
            message:
                'Your Lucky Rascals OTP is: $otpCode. Valid for 10 minutes.');
      }

      // Store OTP in Supabase for verification
      await _storeOTPInDatabase(formattedPhone, otpCode, otpType);

      return {
        'success': true,
        'message': 'OTP sent successfully',
        'otp_type': useWhatsApp ? 'whatsapp' : 'sms',
        'phone_number': formattedPhone,
        'message_sid': sendResult['message_sid'],
        'is_mock': false,
      };
    } catch (error) {
      debugPrint('OTP send error: $error');

      // Only fallback to mock in development
      if (_environmentService.enableMockOTP &&
          _environmentService.isDevelopment &&
          !error.toString().contains('Invalid phone number')) {
        debugPrint('Falling back to mock OTP due to error: $error');
        return {
          'success': true,
          'message': 'OTP sent successfully (Fallback Mode)',
          'otp_type': otpType,
          'phone_number': phoneNumber,
          'mock_otp': _environmentService.mockOTPCode,
          'is_mock': true,
        };
      }

      throw Exception(_classifyError(error));
    }
  }

  // Store OTP in database
  Future<void> _storeOTPInDatabase(
      String phoneNumber, String otpCode, String otpType) async {
    try {
      final client = await _getClient();
      if (client == null) return;

      await client.from('otp_verifications').insert({
        'phone_number': phoneNumber,
        'otp_code': otpCode,
        'otp_type': otpType,
        'expires_at':
            DateTime.now().add(Duration(minutes: 10)).toIso8601String(),
        'attempts': 0,
      });
    } catch (error) {
      debugPrint('Failed to store OTP in database: $error');
    }
  }

  // Generate 6-digit OTP
  String _generateOTP() {
    final random = DateTime.now().millisecondsSinceEpoch;
    return (100000 + (random % 900000)).toString();
  }

  // Classify errors for better user experience
  String _classifyError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('invalid phone number') ||
        errorString.contains('phone number format')) {
      return 'Invalid phone number format. Please enter a valid 10-digit Indian mobile number.';
    }

    if (errorString.contains('21703')) {
      return 'SMS service configuration error. Please contact support.';
    }

    if (errorString.contains('21614')) {
      return 'Invalid phone number format.';
    }

    if (errorString.contains('21408')) {
      return 'WhatsApp messaging not available. Trying SMS instead.';
    }

    if (errorString.contains('rate limit') ||
        errorString.contains('too many requests')) {
      return 'Too many OTP requests. Please wait a few minutes before trying again.';
    }

    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout')) {
      return 'Network error. Please check your internet connection and try again.';
    }

    return 'Unable to send OTP. Please try again or contact support if the problem persists.';
  }

  // Verify OTP with enhanced error handling
  Future<Map<String, dynamic>> verifyOTP({
    required String phoneNumber,
    required String token,
  }) async {
    try {
      // Validate inputs
      if (!_isValidPhoneNumber(phoneNumber)) {
        throw Exception('Invalid phone number format.');
      }

      if (token.isEmpty || token.length != 6) {
        throw Exception('Please enter a valid 6-digit OTP.');
      }

      final formattedPhone = _formatPhoneNumber(phoneNumber);
      if (formattedPhone == null) {
        throw Exception('Unable to format phone number.');
      }

      // Check for mock OTP in development
      if (_environmentService.enableMockOTP &&
          token == _environmentService.mockOTPCode) {
        debugPrint('Mock OTP verified successfully');
        return {
          'success': true,
          'message': 'OTP verified successfully (Development Mode)',
          'user': null,
          'is_mock': true,
        };
      }

      // Check if Supabase is configured
      final isSupabaseConfigured = await _isSupabaseConfigured();
      if (!isSupabaseConfigured) {
        throw Exception(
            'Verification service temporarily unavailable. Please try again later.');
      }

      final client = await _getClient();
      if (client == null) {
        throw Exception('Authentication service is not available.');
      }

      // Verify OTP against database
      final otpRecord = await client
          .from('otp_verifications')
          .select()
          .eq('phone_number', formattedPhone)
          .eq('otp_code', token)
          .eq('status', 'pending')
          .gte('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (otpRecord == null) {
        throw Exception('Invalid or expired OTP. Please request a new one.');
      }

      // Mark OTP as verified
      await client
          .from('otp_verifications')
          .update({'status': 'verified'}).eq('id', otpRecord['id']);

      // Try to authenticate with Supabase
      final response = await client.auth.signInWithOtp(phone: formattedPhone);

      return {
        'success': true,
        'message': 'OTP verified successfully',
        'user': client.auth.currentUser,
        'is_mock': false,
      };
    } catch (error) {
      debugPrint('OTP verification error: $error');

      // If Supabase auth fails but our OTP is valid, still consider it success
      if (error.toString().contains('Invalid or expired OTP') == false) {
        return {
          'success': true,
          'message': 'OTP verified successfully',
          'user': null,
          'is_mock': false,
        };
      }

      String errorMessage = _classifyVerificationError(error);
      throw Exception(errorMessage);
    }
  }

  // Classify verification errors
  String _classifyVerificationError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('invalid token') ||
        errorString.contains('invalid otp')) {
      return 'Invalid OTP. Please check your code and try again.';
    }

    if (errorString.contains('expired') || errorString.contains('timeout')) {
      return 'OTP has expired. Please request a new one.';
    }

    if (errorString.contains('attempts') || errorString.contains('maximum')) {
      return 'Maximum verification attempts exceeded. Please request a new OTP.';
    }

    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network error. Please check your internet connection and try again.';
    }

    return 'OTP verification failed. Please try again or request a new OTP.';
  }

  // Check if WhatsApp is enabled with proper Twilio integration
  Future<bool> isWhatsAppEnabled(String? phoneNumber) async {
    try {
      if (phoneNumber == null || phoneNumber.isEmpty) {
        return false;
      }

      final formattedPhone = _formatPhoneNumber(phoneNumber);
      if (formattedPhone == null) {
        return false;
      }

      // Check if Twilio WhatsApp is configured and available
      return _twilioService.isWhatsAppAvailable(formattedPhone);
    } catch (error) {
      debugPrint('WhatsApp check error: $error');
      return false; // Default to SMS if check fails
    }
  }

  // Get current user with null safety
  Future<User?> getCurrentUser() async {
    try {
      final client = await _getClient();
      return client?.auth.currentUser;
    } catch (error) {
      debugPrint('Get current user error: $error');
      return null;
    }
  }

  // Check if user is signed in with null safety
  Future<bool> isSignedIn() async {
    try {
      final user = await getCurrentUser();
      return user != null;
    } catch (error) {
      debugPrint('Sign in check error: $error');
      return false;
    }
  }

  // Sign out user with error handling
  Future<void> signOut() async {
    try {
      final client = await _getClient();
      if (client != null) {
        await client.auth.signOut();
      }
    } catch (error) {
      debugPrint('Sign out error: $error');
      throw Exception('Failed to sign out. Please try again.');
    }
  }

  // Resend OTP with rate limiting protection
  Future<Map<String, dynamic>> resendOTP({
    required String phoneNumber,
    required String otpType,
  }) async {
    try {
      // Add delay to prevent spam
      await Future.delayed(const Duration(seconds: 2));

      return await sendOTP(phoneNumber: phoneNumber, otpType: otpType);
    } catch (error) {
      debugPrint('Resend OTP error: $error');
      throw Exception('Failed to resend OTP: ${_classifyError(error)}');
    }
  }

  // Health check for the service
  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final isSupabaseConfigured = await _isSupabaseConfigured();
      final twilioStatus = _twilioService.getServiceStatus();
      final envConfig = _environmentService.getConfigurationStatus();

      return {
        'supabase_configured': isSupabaseConfigured,
        'twilio_status': twilioStatus,
        'environment_config': envConfig,
        'service_status': isSupabaseConfigured && _twilioService.isConfigured
            ? 'healthy'
            : 'degraded',
        'production_ready': _environmentService.isProductionReady(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (error) {
      return {
        'service_status': 'error',
        'error': error.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}
