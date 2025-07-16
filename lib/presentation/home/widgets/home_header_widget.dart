import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class HomeHeaderWidget extends StatelessWidget {
  final Map<String, dynamic>? userProfile;
  final VoidCallback onProfileTap;
  final VoidCallback onLogout;

  const HomeHeaderWidget({
    Key? key,
    required this.userProfile,
    required this.onProfileTap,
    required this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.lightTheme.primaryColor,
            AppTheme.lightTheme.primaryColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            // Top row with profile and menu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Profile section
                GestureDetector(
                  onTap: onProfileTap,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 6.w,
                        backgroundColor: Colors.white,
                        child: CustomIconWidget(
                          iconName: 'person',
                          color: AppTheme.lightTheme.primaryColor,
                          size: 6.w,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back!',
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          Text(
                            userProfile?['phone_number'] ?? 'User',
                            style: AppTheme.lightTheme.textTheme.bodyLarge
                                ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Menu button
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'profile') {
                      onProfileTap();
                    } else if (value == 'logout') {
                      onLogout();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'person',
                            color: Colors.grey[600]!,
                            size: 5.w,
                          ),
                          SizedBox(width: 2.w),
                          Text('Profile'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'logout',
                            color: Colors.grey[600]!,
                            size: 5.w,
                          ),
                          SizedBox(width: 2.w),
                          Text('Logout'),
                        ],
                      ),
                    ),
                  ],
                  icon: CustomIconWidget(
                    iconName: 'more_vert',
                    color: Colors.white,
                    size: 6.w,
                  ),
                ),
              ],
            ),

            SizedBox(height: 3.h),

            // Earnings display
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Total Earnings',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '₹',
                        style: AppTheme.lightTheme.textTheme.headlineMedium
                            ?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${userProfile?['total_earnings']?.toStringAsFixed(2) ?? '0.00'}',
                        style: AppTheme.lightTheme.textTheme.headlineMedium
                            ?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Keep scanning to earn more!',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
