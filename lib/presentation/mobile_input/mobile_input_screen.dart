import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/otp_service.dart';

class MobileInputScreen extends StatefulWidget {
  const MobileInputScreen({Key? key}) : super(key: key);

  @override
  State<MobileInputScreen> createState() => _MobileInputScreenState();
}

class _MobileInputScreenState extends State<MobileInputScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  final OTPService _otpService = OTPService();

  bool _isLoading = false;
  bool _isPhoneValid = false;
  String _storeId = '';

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_validatePhone);

    // Get store ID from arguments if navigated from QR scanner
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as String?;
      if (args != null) {
        setState(() {
          _storeId = args;
        });
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _validatePhone() {
    final phone = _phoneController.text.trim();
    final isValid = _isValidPhoneNumber(phone);

    if (isValid != _isPhoneValid) {
      setState(() {
        _isPhoneValid = isValid;
      });
    }
  }

  bool _isValidPhoneNumber(String phone) {
    // Remove any non-digit characters
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');

    // Check if it's a valid Indian mobile number
    if (cleanPhone.length == 10) {
      return cleanPhone.startsWith(RegExp(r'[6-9]'));
    } else if (cleanPhone.length == 12) {
      return cleanPhone.startsWith('91') &&
          cleanPhone.substring(2).startsWith(RegExp(r'[6-9]'));
    } else if (cleanPhone.length == 13) {
      return cleanPhone.startsWith('+91') &&
          cleanPhone.substring(3).startsWith(RegExp(r'[6-9]'));
    }

    return false;
  }

  String _formatPhoneNumber(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanPhone.length == 10) {
      return '+91$cleanPhone';
    } else if (cleanPhone.length == 12 && cleanPhone.startsWith('91')) {
      return '+$cleanPhone';
    } else if (cleanPhone.length == 13 && cleanPhone.startsWith('91')) {
      return '+$cleanPhone';
    }

    return '+91$cleanPhone';
  }

  Future<void> _proceedToOTP() async {
    if (!_isPhoneValid || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final formattedPhone = _formatPhoneNumber(_phoneController.text.trim());

      // Check if WhatsApp is enabled for this number
      final isWhatsAppEnabled =
          await _otpService.isWhatsAppEnabled(formattedPhone);

      // Send OTP
      await _otpService.sendOTP(
        phoneNumber: formattedPhone,
        otpType: isWhatsAppEnabled ? 'whatsapp' : 'sms',
      );

      if (mounted) {
        // Navigate to OTP verification screen
        Navigator.pushNamed(
          context,
          AppRoutes.otpVerification,
          arguments: {
            'phone_number': formattedPhone,
            'otp_type': isWhatsAppEnabled ? 'whatsapp' : 'sms',
            'store_id': _storeId,
          },
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send OTP: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              height: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top,
              padding: EdgeInsets.all(6.w),
              child: Column(
                children: [
                  // Back button and title
                  _buildHeader(),

                  SizedBox(height: 4.h),

                  // Logo and welcome text
                  _buildWelcomeSection(),

                  SizedBox(height: 6.h),

                  // Phone input form
                  _buildPhoneInputForm(),

                  SizedBox(height: 4.h),

                  // UPI requirement note
                  _buildUPINote(),

                  Spacer(),

                  // Continue button
                  _buildContinueButton(),

                  SizedBox(height: 2.h),

                  // Terms and privacy
                  _buildTermsText(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CustomIconWidget(
              iconName: 'arrow_back',
              color: Colors.black,
              size: 6.w,
            ),
          ),
        ),
        Text(
          'Enter Mobile Number',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(width: 10.w), // Spacer for alignment
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      children: [
        // Lucky Rascals logo
        Container(
          width: 20.w,
          height: 20.w,
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.primaryColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: CustomIconWidget(
              iconName: 'qr_code_scanner',
              color: Colors.white,
              size: 10.w,
            ),
          ),
        ),

        SizedBox(height: 3.h),

        Text(
          'Welcome to Lucky Rascals!',
          style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 1.h),

        Text(
          'Enter your mobile number to get started with earning rewards',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPhoneInputForm() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mobile Number',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),

          SizedBox(height: 2.h),

          // Phone number input
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: _isPhoneValid ? Colors.green : Colors.grey[300]!,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Country code
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '🇮🇳',
                        style: AppTheme.lightTheme.textTheme.bodyLarge,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        '+91',
                        style:
                            AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Phone number input
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    focusNode: _phoneFocusNode,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: InputDecoration(
                      hintText: '9876543210',
                      hintStyle:
                          AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[400],
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(4.w),
                    ),
                    style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // Validation icon
                if (_phoneController.text.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(right: 4.w),
                    child: CustomIconWidget(
                      iconName: _isPhoneValid ? 'check_circle' : 'error',
                      color: _isPhoneValid ? Colors.green : Colors.red,
                      size: 6.w,
                    ),
                  ),
              ],
            ),
          ),

          if (_phoneController.text.isNotEmpty && !_isPhoneValid)
            Padding(
              padding: EdgeInsets.only(top: 1.h),
              child: Text(
                'Please enter a valid 10-digit mobile number',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: Colors.red,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUPINote() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomIconWidget(
            iconName: 'info',
            color: Colors.amber[700]!,
            size: 5.w,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UPI Wallet Required',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.amber[700],
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Make sure your mobile number is linked to a UPI wallet (PhonePe, GPay, Paytm) to receive instant rewards.',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: Colors.amber[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isPhoneValid && !_isLoading ? _proceedToOTP : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.lightTheme.primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          padding: EdgeInsets.symmetric(vertical: 4.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                width: 5.w,
                height: 5.w,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Continue',
                style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildTermsText() {
    return Text(
      'By continuing, you agree to our Terms of Service and Privacy Policy. You must be 18+ to participate.',
      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
        color: Colors.grey[600],
      ),
      textAlign: TextAlign.center,
    );
  }
}
