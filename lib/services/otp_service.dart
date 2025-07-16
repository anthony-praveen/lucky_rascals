import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

class OTPService {
  static final OTPService _instance = OTPService._internal();
  factory OTPService() => _instance;
  OTPService._internal();

  Future<SupabaseClient> get client async => await SupabaseService().client;

  // Generate and send OTP
  Future<void> sendOTP({
    required String phoneNumber,
    required String otpType, // 'whatsapp' or 'sms'
  }) async {
    try {
      final supabase = await client;

      // Generate 6-digit OTP
      final otp = _generateOTP();

      // Store OTP in database
      await supabase.from('otp_verifications').insert({
        'phone_number': phoneNumber,
        'otp_code': otp,
        'otp_type': otpType,
        'expires_at':
            DateTime.now().add(Duration(minutes: 10)).toIso8601String(),
      });

      // TODO: Integrate with actual SMS/WhatsApp API
      // For now, we'll just simulate sending
      if (otpType == 'whatsapp') {
        await _sendWhatsAppOTP(phoneNumber, otp);
      } else {
        await _sendSMSOTP(phoneNumber, otp);
      }
    } catch (error) {
      throw Exception('Failed to send OTP: $error');
    }
  }

  // Verify OTP
  Future<bool> verifyOTP({
    required String phoneNumber,
    required String otpCode,
  }) async {
    try {
      final supabase = await client;

      // Check if OTP exists and is valid
      final response = await supabase
          .from('otp_verifications')
          .select()
          .eq('phone_number', phoneNumber)
          .eq('otp_code', otpCode)
          .eq('status', 'pending')
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isEmpty) {
        return false;
      }

      // Mark OTP as verified
      await supabase
          .from('otp_verifications')
          .update({'status': 'verified'}).eq('id', response.first['id']);

      return true;
    } catch (error) {
      throw Exception('Failed to verify OTP: $error');
    }
  }

  // Check if phone number is WhatsApp enabled
  Future<bool> isWhatsAppEnabled(String phoneNumber) async {
    try {
      // TODO: Implement actual WhatsApp check
      // For now, simulate based on phone number pattern
      return phoneNumber.contains('91') && phoneNumber.length >= 10;
    } catch (error) {
      return false;
    }
  }

  // Generate random 6-digit OTP
  String _generateOTP() {
    final random = DateTime.now().millisecondsSinceEpoch;
    return (random % 900000 + 100000).toString();
  }

  // Send WhatsApp OTP (mock implementation)
  Future<void> _sendWhatsAppOTP(String phoneNumber, String otp) async {
    // TODO: Integrate with WhatsApp Business API
    await Future.delayed(Duration(seconds: 1));
    print('WhatsApp OTP sent to $phoneNumber: $otp');
  }

  // Send SMS OTP (mock implementation)
  Future<void> _sendSMSOTP(String phoneNumber, String otp) async {
    // TODO: Integrate with SMS service provider
    await Future.delayed(Duration(seconds: 1));
    print('SMS OTP sent to $phoneNumber: $otp');
  }

  // Resend OTP
  Future<void> resendOTP({
    required String phoneNumber,
    required String otpType,
  }) async {
    try {
      final supabase = await client;

      // Mark previous OTPs as failed
      await supabase
          .from('otp_verifications')
          .update({'status': 'failed'})
          .eq('phone_number', phoneNumber)
          .eq('status', 'pending');

      // Send new OTP
      await sendOTP(phoneNumber: phoneNumber, otpType: otpType);
    } catch (error) {
      throw Exception('Failed to resend OTP: $error');
    }
  }
}
