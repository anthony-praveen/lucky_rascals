import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ResendTimerWidget extends StatelessWidget {
  final bool isEnabled;
  final int countdown;
  final bool isLoading;
  final VoidCallback onResendPressed;

  const ResendTimerWidget({
    Key? key,
    required this.isEnabled,
    required this.countdown,
    required this.isLoading,
    required this.onResendPressed,
  }) : super(key: key);

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Countdown timer
        if (!isEnabled)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomIconWidget(
                  iconName: 'timer',
                  color: Colors.grey[600]!,
                  size: 4.w,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Resend in ${_formatTime(countdown)}',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

        // Resend button
        if (isEnabled)
          TextButton(
            onPressed: isLoading ? null : onResendPressed,
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: isLoading
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 4.w,
                        height: 4.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.lightTheme.primaryColor,
                          ),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'Sending...',
                        style:
                            AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.lightTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName: 'refresh',
                        color: AppTheme.lightTheme.primaryColor,
                        size: 4.w,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'Resend OTP',
                        style:
                            AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.lightTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),

        SizedBox(height: 2.h),

        // Didn't receive code text
        Text(
          'Didn\'t receive the code?',
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
