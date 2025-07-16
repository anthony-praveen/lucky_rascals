import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class TrustIndicatorsWidget extends StatelessWidget {
  const TrustIndicatorsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Security badges
        _buildSecurityBadges(),

        SizedBox(height: 3.h),

        // Privacy assurance
        _buildPrivacyAssurance(),

        SizedBox(height: 3.h),

        // UPI requirement info
        _buildUPIRequirement(),
      ],
    );
  }

  Widget _buildSecurityBadges() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'security',
            color: Colors.green[600]!,
            size: 6.w,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your data is safe with us',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'We use bank-level encryption to protect your information',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: Colors.green[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyAssurance() {
    return Row(
      children: [
        _buildTrustBadge(
          icon: 'verified',
          text: 'Verified\nPlatform',
          color: Colors.blue,
        ),
        SizedBox(width: 4.w),
        _buildTrustBadge(
          icon: 'no_encryption',
          text: 'No Spam\nGuaranteed',
          color: Colors.purple,
        ),
        SizedBox(width: 4.w),
        _buildTrustBadge(
          icon: 'privacy_tip',
          text: 'Privacy\nProtected',
          color: Colors.teal,
        ),
      ],
    );
  }

  Widget _buildTrustBadge({
    required String icon,
    required String text,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: CustomIconWidget(
                iconName: icon,
                color: color,
                size: 5.w,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              text,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUPIRequirement() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'account_balance_wallet',
                color: Colors.amber[700]!,
                size: 6.w,
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
                      'Make sure your mobile number is linked to a UPI wallet to receive instant rewards',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: Colors.amber[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              _buildUPIProvider('PhonePe', Colors.purple),
              SizedBox(width: 2.w),
              _buildUPIProvider('GPay', Colors.blue),
              SizedBox(width: 2.w),
              _buildUPIProvider('Paytm', Colors.indigo),
              SizedBox(width: 2.w),
              _buildUPIProvider('Others', Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUPIProvider(String name, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 2.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          name,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
