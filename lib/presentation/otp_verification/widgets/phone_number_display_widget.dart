import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PhoneNumberDisplayWidget extends StatelessWidget {
  final String phoneNumber;
  final String otpType;
  final VoidCallback onEditPressed;

  const PhoneNumberDisplayWidget({
    Key? key,
    required this.phoneNumber,
    required this.otpType,
    required this.onEditPressed,
  }) : super(key: key);

  String _getMaskedPhoneNumber() {
    if (phoneNumber.length >= 10) {
      final lastFour = phoneNumber.substring(phoneNumber.length - 4);
      final countryCode = phoneNumber.startsWith('+91') ? '+91' : '';
      return '$countryCode ******$lastFour';
    }
    return phoneNumber;
  }

  @override
  Widget build(BuildContext context) {
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
        children: [
          // Phone number with edit button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // OTP type icon
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: otpType == 'whatsapp'
                      ? Colors.green[50]
                      : Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: otpType == 'whatsapp' ? 'whatsapp' : 'sms',
                  color: otpType == 'whatsapp'
                      ? Colors.green[600]!
                      : Colors.blue[600]!,
                  size: 4.w,
                ),
              ),

              SizedBox(width: 3.w),

              // Phone number
              Text(
                _getMaskedPhoneNumber(),
                style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16.sp,
                ),
              ),

              SizedBox(width: 3.w),

              // Edit button
              GestureDetector(
                onTap: onEditPressed,
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomIconWidget(
                    iconName: 'edit',
                    color: Colors.grey[600]!,
                    size: 4.w,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // OTP delivery method info
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.w),
            decoration: BoxDecoration(
              color: otpType == 'whatsapp' ? Colors.green[50] : Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomIconWidget(
                  iconName: 'info',
                  color: otpType == 'whatsapp'
                      ? Colors.green[600]!
                      : Colors.blue[600]!,
                  size: 3.5.w,
                ),
                SizedBox(width: 2.w),
                Text(
                  otpType == 'whatsapp'
                      ? 'Code sent via WhatsApp'
                      : 'Code sent via SMS',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: otpType == 'whatsapp'
                        ? Colors.green[600]
                        : Colors.blue[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
