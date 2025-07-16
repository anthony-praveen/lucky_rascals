import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/otp_service.dart';
import './widgets/phone_input_widget.dart';
import './widgets/trust_indicators_widget.dart';

class MobileNumberInput extends StatefulWidget {
  const MobileNumberInput({Key? key}) : super(key: key);

  @override
  State<MobileNumberInput> createState() => _MobileNumberInputState();
}

class _MobileNumberInputState extends State<MobileNumberInput>
    with TickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  final OTPService _otpService = OTPService();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  bool _isPhoneValid = false;
  String _storeId = '';
  String? _lastErrorMessage;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_validatePhone);
    _setupAnimations();

    // Get store ID from arguments if navigated from QR scanner
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as String?;
      if (args != null) {
        setState(() {
          _storeId = args;
        });
      }
      _startAnimation();
    });
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _startAnimation() {
    _animationController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    _animationController.dispose();
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

  Future<void> _sendOTP() async {
    if (!_isPhoneValid || _isLoading) return;

    setState(() {
      _isLoading = true;
      _lastErrorMessage = null;
    });

    try {
      final formattedPhone = _formatPhoneNumber(_phoneController.text.trim());

      // Check if WhatsApp is enabled for this number
      final isWhatsAppEnabled =
          await _otpService.isWhatsAppEnabled(formattedPhone);

      // Send OTP with comprehensive error handling
      final result = await _otpService.sendOTP(
        phoneNumber: formattedPhone,
        otpType: isWhatsAppEnabled ? 'whatsapp' : 'sms',
      );

      if (mounted && result['success'] == true) {
        // Show success feedback
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                CustomIconWidget(
                  iconName: 'check_circle',
                  color: Colors.white,
                  size: 5.w,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(result['message'] ?? 'OTP sent successfully!'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate to OTP verification screen
        Navigator.pushNamed(
          context,
          AppRoutes.otpVerification,
          arguments: {
            'phone_number': formattedPhone,
            'otp_type': isWhatsAppEnabled ? 'whatsapp' : 'sms',
            'store_id': _storeId,
            'mock_otp': result['mock_otp'], // For development
          },
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _lastErrorMessage = error.toString().replaceFirst('Exception: ', '');
        });

        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                CustomIconWidget(
                  iconName: 'error',
                  color: Colors.white,
                  size: 5.w,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(_lastErrorMessage ?? 'Failed to send OTP'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _sendOTP(),
            ),
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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                child: Container(
                  height: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top,
                  padding: EdgeInsets.all(6.w),
                  child: Column(
                    children: [
                      // Header with back button
                      _buildHeader(),

                      SizedBox(height: 4.h),

                      // Welcome section with branding
                      _buildWelcomeSection(),

                      SizedBox(height: 6.h),

                      // Phone input card
                      PhoneInputWidget(
                        controller: _phoneController,
                        focusNode: _phoneFocusNode,
                        isValid: _isPhoneValid,
                        onChanged: _validatePhone,
                      ),

                      SizedBox(height: 4.h),

                      // Trust indicators
                      TrustIndicatorsWidget(),

                      Spacer(),

                      // Send OTP button
                      _buildSendOTPButton(),

                      SizedBox(height: 2.h),

                      // Terms and privacy
                      _buildTermsText(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
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
        Expanded(
          child: Text(
            'Enter Mobile Number',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(width: 10.w), // Spacer for alignment
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      children: [
        // App logo with gradient background
        Container(
          width: 25.w,
          height: 25.w,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryLight,
                AppTheme.primaryLight.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryLight.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: CustomIconWidget(
              iconName: 'qr_code_scanner',
              color: Colors.white,
              size: 12.w,
            ),
          ),
        ),

        SizedBox(height: 3.h),

        // Welcome text
        Text(
          'Welcome to Lucky Rascals!',
          style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryLight,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 1.h),

        // Subtitle
        Text(
          'Enter your mobile number to get started\nwith earning instant rewards',
          style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 2.h),

        // Value proposition
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              CustomIconWidget(
                iconName: 'trending_up',
                color: Colors.blue[600]!,
                size: 5.w,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  'Scan QR codes, watch ads, earn money instantly!',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSendOTPButton() {
    return Column(
      children: [
        // Show error message if present
        if (_lastErrorMessage != null)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(3.w),
            margin: EdgeInsets.only(bottom: 2.h),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[600], size: 5.w),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    _lastErrorMessage!,
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 12.sp,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _lastErrorMessage = null),
                  child: Icon(Icons.close, color: Colors.red[600], size: 4.w),
                ),
              ],
            ),
          ),

        // Send OTP button
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: _isPhoneValid && !_isLoading
                ? LinearGradient(
                    colors: [
                      AppTheme.primaryLight,
                      AppTheme.primaryLight.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isPhoneValid && !_isLoading
                ? [
                    BoxShadow(
                      color: AppTheme.primaryLight.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: ElevatedButton(
            onPressed: _isPhoneValid && !_isLoading ? _sendOTP : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isPhoneValid && !_isLoading
                  ? Colors.transparent
                  : Colors.grey[300],
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
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
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: 'send',
                        color: Colors.white,
                        size: 5.w,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'Send OTP',
                        style:
                            AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsText() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
          color: Colors.grey[600],
        ),
        children: [
          TextSpan(text: 'By continuing, you agree to our '),
          TextSpan(
            text: 'Terms of Service',
            style: TextStyle(
              color: AppTheme.primaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            style: TextStyle(
              color: AppTheme.primaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(text: '.\nYou must be 18+ to participate.'),
        ],
      ),
    );
  }
}
