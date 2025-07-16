import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';

class EarningsShowcaseScreen extends StatelessWidget {
  const EarningsShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      Text('Start Earning Today!',
                          style: GoogleFonts.inter(
                              fontSize: 24.sp, fontWeight: FontWeight.bold)),
                      SizedBox(height: 1.h),
                      Text(
                          'Discover nearby businesses and earn rewards instantly',
                          style: GoogleFonts.inter(fontSize: 14.sp)),
                      SizedBox(height: 4.h),

                      // Main Image Section
                      Container(
                          width: double.infinity,
                          height: 50.h,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withAlpha(26),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4)),
                              ]),
                          child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset('assets/images/no-image.jpg',
                                  fit: BoxFit.cover))),
                      SizedBox(height: 4.h),

                      // Features Section
                      _buildFeatureItem(
                          icon: Icons.location_on,
                          title: 'Find Nearby Stores',
                          description: 'Discover local businesses around you'),
                      SizedBox(height: 2.h),
                      _buildFeatureItem(
                          icon: Icons.account_balance_wallet,
                          title: 'Instant Rewards',
                          description: 'Earn money with every QR code scan'),
                      SizedBox(height: 2.h),
                      _buildFeatureItem(
                          icon: Icons.map,
                          title: 'Easy Navigation',
                          description: 'Get directions to reward locations'),

                      const Spacer(),

                      // CTA Button
                      SizedBox(
                          width: double.infinity,
                          height: 6.h,
                          child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, AppRoutes.home);
                              },
                              style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12))),
                              child: Text('Start Earning Now',
                                  style: GoogleFonts.inter(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600)))),
                    ]))));
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(children: [
      Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 6.w)),
      SizedBox(width: 3.w),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: GoogleFonts.inter(
                fontSize: 16.sp, fontWeight: FontWeight.w600)),
        Text(description, style: GoogleFonts.inter(fontSize: 14.sp)),
      ])),
    ]);
  }
}
