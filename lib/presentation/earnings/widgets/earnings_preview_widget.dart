import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class EarningsPreviewWidget extends StatelessWidget {
  final String amount;
  final VoidCallback? onTap;

  const EarningsPreviewWidget({
    super.key,
    this.amount = '₹250',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.blue,
                  Colors.blue.withAlpha(204),
                ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(blurRadius: 10, offset: const Offset(0, 4)),
                ]),
            child: Column(children: [
              // Header
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Your Earnings',
                    style: GoogleFonts.inter(
                        fontSize: 16.sp, fontWeight: FontWeight.w600)),
                Icon(Icons.trending_up, size: 6.w),
              ]),
              SizedBox(height: 2.h),

              // Amount Display
              Text(amount,
                  style: GoogleFonts.inter(
                      fontSize: 32.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 1.h),

              // Subtitle
              Text('Total earned this week',
                  style: GoogleFonts.inter(fontSize: 14.sp)),
              SizedBox(height: 2.h),

              // Featured Image Preview
              Container(
                  width: double.infinity,
                  height: 15.h,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withAlpha(51),
                            blurRadius: 8,
                            offset: const Offset(0, 2)),
                      ]),
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset('assets/images/no-image.jpg',
                          fit: BoxFit.cover))),
              SizedBox(height: 2.h),

              // Action Button
              SizedBox(
                  width: double.infinity,
                  height: 5.h,
                  child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8))),
                      child: Text('View Details',
                          style: GoogleFonts.inter(
                              fontSize: 14.sp, fontWeight: FontWeight.w600)))),
            ])));
  }
}
