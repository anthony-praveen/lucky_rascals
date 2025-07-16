import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../widgets/custom_icon_widget.dart';

class BusinessDetailsSectionWidget extends StatelessWidget {
  final String businessName;
  final String description;
  final String location;
  final VoidCallback onDirectionsPressed;

  const BusinessDetailsSectionWidget({
    Key? key,
    required this.businessName,
    required this.description,
    required this.location,
    required this.onDirectionsPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.withAlpha(26),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
            border: Border.all(color: Colors.grey.withAlpha(51), width: 1)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Section title
          Text('About $businessName',
              style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87)),

          SizedBox(height: 2.h),

          // Description
          Text(description,
              style: GoogleFonts.inter(
                  fontSize: 14.sp, color: Colors.grey[700], height: 1.5)),

          SizedBox(height: 3.h),

          // Location section
          Row(children: [
            CustomIconWidget(iconName: 'location', size: 20),
            SizedBox(width: 2.w),
            Expanded(
                child: Text(location,
                    style: GoogleFonts.inter(
                        fontSize: 14.sp, color: Colors.grey[700]))),
          ]),

          SizedBox(height: 2.h),

          // Directions button
          SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: onDirectionsPressed,
                  style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                            iconName: 'directions',
                            size: 20,
                            color: Colors.white),
                        SizedBox(width: 2.w),
                        Text('Get Directions',
                            style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ]))),

          SizedBox(height: 3.h),

          // Operating hours (mock data)
          _buildInfoRow('Operating Hours', '9:00 AM - 10:00 PM'),

          SizedBox(height: 1.h),

          // Contact info (mock data)
          _buildInfoRow('Contact', '+91 98765 43210'),

          SizedBox(height: 2.h),

          // Social proof
          Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                  color: Colors.green.withAlpha(26),
                  borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                CustomIconWidget(
                    iconName: 'verified', size: 20, color: Colors.green),
                SizedBox(width: 2.w),
                Expanded(
                    child: Text('Verified business with 500+ happy customers',
                        style: GoogleFonts.inter(
                            fontSize: 12.sp, color: Colors.green[700]))),
              ])),
        ]));
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
          width: 30.w,
          child: Text(label,
              style:
                  GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey[600]))),
      Expanded(
          child: Text(value,
              style:
                  GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey[700]))),
    ]);
  }
}
