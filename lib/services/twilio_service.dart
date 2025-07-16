import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class TwilioService {
  static final TwilioService _instance = TwilioService._internal();
  factory TwilioService() => _instance;
  TwilioService._internal();

  // Twilio configuration from environment
  static const String _accountSid =
      String.fromEnvironment('TWILIO_ACCOUNT_SID', defaultValue: '');
  static const String _authToken =
      String.fromEnvironment('TWILIO_AUTH_TOKEN', defaultValue: '');
  static const String _messagingServiceSid =
      String.fromEnvironment('TWILIO_MESSAGING_SERVICE_SID', defaultValue: '');
  static const String _whatsappNumber =
      String.fromEnvironment('TWILIO_WHATSAPP_NUMBER', defaultValue: '');

  final Dio _dio = Dio();

  bool get isConfigured =>
      _accountSid.isNotEmpty &&
      _authToken.isNotEmpty &&
      _messagingServiceSid.isNotEmpty;

  // Send SMS via Twilio
  Future<Map<String, dynamic>> sendSMS({
    required String toNumber,
    required String message,
  }) async {
    try {
      if (!isConfigured) {
        throw Exception('Twilio SMS not configured');
      }

      final response = await _dio.post(
        'https://api.twilio.com/2010-04-01/Accounts/$_accountSid/Messages.json',
        data: {
          'To': toNumber,
          'MessagingServiceSid': _messagingServiceSid,
          'Body': message,
        },
        options: Options(
          headers: {
            'Authorization': 'Basic ${_getBasicAuth()}',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
      );

      return {
        'success': true,
        'message_sid': response.data['sid'],
        'status': response.data['status'],
      };
    } catch (error) {
      debugPrint('Twilio SMS error: $error');
      throw Exception(_parseTwilioError(error));
    }
  }

  // Send WhatsApp message via Twilio
  Future<Map<String, dynamic>> sendWhatsApp({
    required String toNumber,
    required String message,
  }) async {
    try {
      if (!isConfigured || _whatsappNumber.isEmpty) {
        throw Exception('Twilio WhatsApp not configured');
      }

      final response = await _dio.post(
        'https://api.twilio.com/2010-04-01/Accounts/$_accountSid/Messages.json',
        data: {
          'To': 'whatsapp:$toNumber',
          'From': 'whatsapp:$_whatsappNumber',
          'Body': message,
        },
        options: Options(
          headers: {
            'Authorization': 'Basic ${_getBasicAuth()}',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
      );

      return {
        'success': true,
        'message_sid': response.data['sid'],
        'status': response.data['status'],
      };
    } catch (error) {
      debugPrint('Twilio WhatsApp error: $error');
      throw Exception(_parseTwilioError(error));
    }
  }

  // Check if WhatsApp is available for number
  bool isWhatsAppAvailable(String phoneNumber) {
    return _whatsappNumber.isNotEmpty &&
        phoneNumber.startsWith('+91') &&
        isConfigured;
  }

  String _getBasicAuth() {
    final credentials = '$_accountSid:$_authToken';
    return base64.encode(utf8.encode(credentials));
  }

  String _parseTwilioError(dynamic error) {
    if (error is DioException) {
      final response = error.response;
      if (response?.data != null && response?.data['message'] != null) {
        final message = response?.data['message'].toString();

        // Handle specific Twilio errors
        if (message?.contains('21703') == true) {
          return 'Messaging Service configuration error. Please contact support.';
        }
        if (message?.contains('21614') == true) {
          return 'Invalid phone number format.';
        }
        if (message?.contains('21408') == true) {
          return 'WhatsApp messaging not available for this number.';
        }

        return message ?? 'SMS/WhatsApp service error';
      }
    }
    return 'Unable to send message. Please try again.';
  }

  // Get service status
  Map<String, dynamic> getServiceStatus() {
    return {
      'sms_configured': _accountSid.isNotEmpty &&
          _authToken.isNotEmpty &&
          _messagingServiceSid.isNotEmpty,
      'whatsapp_configured': isWhatsAppAvailable('+911234567890'),
      'account_sid': _accountSid.isNotEmpty
          ? '${_accountSid.substring(0, 8)}...'
          : 'Not set',
      'messaging_service_sid': _messagingServiceSid.isNotEmpty
          ? '${_messagingServiceSid.substring(0, 8)}...'
          : 'Not set',
    };
  }
}
