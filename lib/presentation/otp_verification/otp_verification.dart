import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../services/otp_service.dart';
import './widgets/otp_input_widget.dart';
import './widgets/phone_number_display_widget.dart';
import './widgets/resend_timer_widget.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({Key? key}) : super(key: key);

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  final OTPService _otpService = OTPService();
  final AuthService _authService = AuthService();

  String _phoneNumber = '';
  String _otpType = '';
  String _storeId = '';
  bool _isLoading = false;
  bool _isVerifying = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isResendEnabled = false;
  int _resendCountdown = 60;

  @override
  void initState() {
    super.initState();
    _initializeArguments();
    _startResendTimer();
  }

  @override
  void dispose() {
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _initializeArguments() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        setState(() {
          _phoneNumber = args['phone_number'] ?? '';
          _otpType = args['otp_type'] ?? '';
          _storeId = args['store_id'] ?? '';
        });
      }
    });
  }

  void _startResendTimer() {
    setState(() {
      _isResendEnabled = false;
      _resendCountdown = 60;
    });

    Future.delayed(Duration(seconds: 1), () {
      if (mounted && _resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
        _startResendTimer();
      } else if (mounted) {
        setState(() {
          _isResendEnabled = true;
        });
      }
    });
  }

  String _getCurrentOTP() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  bool _isOTPComplete() {
    return _getCurrentOTP().length == 6;
  }

  void _clearOTP() {
    for (final controller in _otpControllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  void _showError(String message) {
    setState(() {
      _hasError = true;
      _errorMessage = message;
    });

    // Clear error after 3 seconds
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _hasError = false;
          _errorMessage = '';
        });
      }
    });
  }

  void _onOtpDigitChanged(String value, int index) {
    setState(() {
      _hasError = false;
      _errorMessage = '';
    });

    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }

    if (_isOTPComplete()) {
      _verifyOTP();
    }
  }

  void _onOtpDigitBackspace(int index) {
    if (index > 0 && _otpControllers[index].text.isEmpty) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _verifyOTP() async {
    if (!_isOTPComplete() || _isVerifying) return;

    setState(() {
      _isVerifying = true;
    });

    try {
      final otpCode = _getCurrentOTP();
      await _otpService.verifyOTP(phoneNumber: _phoneNumber, token: otpCode);

      if (mounted) {
        // Show success state briefly
        await _showSuccessState();

        // Navigate to home screen
        Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.home, (route) => false,
            arguments: _storeId.isNotEmpty ? {'store_id': _storeId} : null);
      }
    } catch (error) {
      if (mounted) {
        _showError('Verification failed: ${error.toString()}');
        _clearOTP();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _showSuccessState() async {
    setState(() {
      _hasError = false;
    });

    await Future.delayed(Duration(milliseconds: 500));
  }

  Future<void> _resendOTP() async {
    if (!_isResendEnabled || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _otpService.sendOTP(phoneNumber: _phoneNumber, otpType: _otpType);

      if (mounted) {
        _clearOTP();
        _startResendTimer();

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('OTP sent successfully to $_phoneNumber'),
            backgroundColor: Colors.green));
      }
    } catch (error) {
      if (mounted) {
        _showError('Failed to resend OTP: ${error.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _editPhoneNumber() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey[50],
        body: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark),
            child: SafeArea(
                child: SingleChildScrollView(
                    child: Container(
                        height: MediaQuery.of(context).size.height -
                            MediaQuery.of(context).padding.top,
                        padding: EdgeInsets.all(6.w),
                        child: Column(children: [
                          // Header
                          _buildHeader(),

                          SizedBox(height: 4.h),

                          // Lock icon and title
                          _buildTitleSection(),

                          SizedBox(height: 4.h),

                          // Phone number display
                          PhoneNumberDisplayWidget(
                              phoneNumber: _phoneNumber,
                              otpType: _otpType,
                              onEditPressed: _editPhoneNumber),

                          SizedBox(height: 6.h),

                          // OTP input boxes
                          OtpInputWidget(
                              controllers: _otpControllers,
                              focusNodes: _focusNodes,
                              hasError: _hasError,
                              isVerifying: _isVerifying,
                              onChanged: _onOtpDigitChanged,
                              onBackspace: _onOtpDigitBackspace),

                          SizedBox(height: 2.h),

                          // Error message
                          if (_hasError) _buildErrorMessage(),

                          SizedBox(height: 4.h),

                          // Resend section
                          ResendTimerWidget(
                              isEnabled: _isResendEnabled,
                              countdown: _resendCountdown,
                              isLoading: _isLoading,
                              onResendPressed: _resendOTP),

                          SizedBox(height: 4.h),

                          // Security note
                          _buildSecurityNote(),

                          Spacer(),

                          // Auto-verify note
                          _buildAutoVerifyNote(),
                        ]))))));
  }

  Widget _buildHeader() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
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
                        offset: const Offset(0, 2)),
                  ]),
              child: CustomIconWidget(
                  iconName: 'arrow_back', color: Colors.black, size: 6.w))),
      Text('OTP Verification',
          style: AppTheme.lightTheme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600)),
      SizedBox(width: 10.w), // Spacer for alignment
    ]);
  }

  Widget _buildTitleSection() {
    return Column(children: [
      // Lock icon
      Container(
          width: 18.w,
          height: 18.w,
          decoration: BoxDecoration(
              color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle),
          child: Center(
              child: CustomIconWidget(
                  iconName: 'lock',
                  color: AppTheme.lightTheme.primaryColor,
                  size: 8.w))),

      SizedBox(height: 3.h),

      Text('Enter Verification Code',
          style: AppTheme.lightTheme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center),

      SizedBox(height: 1.h),

      Text('We have sent a 6-digit verification code to\nyour mobile number',
          style: AppTheme.lightTheme.textTheme.bodyMedium
              ?.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center),
    ]);
  }

  Widget _buildErrorMessage() {
    return Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red[200]!)),
        child: Row(children: [
          CustomIconWidget(iconName: 'error', color: Colors.red, size: 5.w),
          SizedBox(width: 2.w),
          Expanded(
              child: Text(_errorMessage,
                  style: AppTheme.lightTheme.textTheme.bodySmall
                      ?.copyWith(color: Colors.red[700]))),
        ]));
  }

  Widget _buildSecurityNote() {
    return Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CustomIconWidget(
              iconName: 'shield', color: Colors.blue[700]!, size: 5.w),
          SizedBox(width: 3.w),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Security Notice',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600, color: Colors.blue[700])),
                SizedBox(height: 0.5.h),
                Text(
                    'This code expires in 10 minutes. Never share your OTP with anyone for security reasons.',
                    style: AppTheme.lightTheme.textTheme.bodySmall
                        ?.copyWith(color: Colors.blue[700])),
              ])),
        ]));
  }

  Widget _buildAutoVerifyNote() {
    return Text('OTP will be automatically verified when entered completely',
        style: AppTheme.lightTheme.textTheme.bodySmall
            ?.copyWith(color: Colors.grey[600]),
        textAlign: TextAlign.center);
  }
}
