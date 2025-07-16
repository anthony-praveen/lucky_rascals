import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../widgets/custom_image_widget.dart';
import '../../../widgets/custom_icon_widget.dart';

class BusinessHeroWidget extends StatelessWidget {
  final String businessName;
  final String campaignName;
  final String location;
  final String? imageUrl;

  const BusinessHeroWidget({
    Key? key,
    required this.businessName,
    required this.campaignName,
    required this.location,
    this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 35.h,
        child: Stack(children: [
          // Background image
          Positioned.fill(
              child: imageUrl != null
                  ? CustomImageWidget(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity)
                  : Container(
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                            Colors.blue.shade400,
                            Colors.purple.shade400,
                          ])),
                      child: Center(
                          child: CustomIconWidget(
                              iconName: 'business',
                              size: 80,
                              color: Colors.white.withAlpha(128))))),

          // Gradient overlay
          Positioned.fill(
              child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                Colors.transparent,
                Colors.black.withAlpha(179),
              ])))),

          // Content
          Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Business name
                        Text(businessName,
                            style: GoogleFonts.inter(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),

                        SizedBox(height: 1.h),

                        // Campaign name
                        Text(campaignName,
                            style: GoogleFonts.inter(
                                fontSize: 16.sp,
                                color: Colors.white.withAlpha(230))),

                        SizedBox(height: 1.h),

                        // Location
                        Row(children: [
                          CustomIconWidget(
                              iconName: 'location',
                              size: 16,
                              color: Colors.white.withAlpha(204)),
                          SizedBox(width: 2.w),
                          Expanded(
                              child: Text(location,
                                  style: GoogleFonts.inter(
                                      fontSize: 14.sp,
                                      color: Colors.white.withAlpha(204)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)),
                        ]),
                      ]))),
        ]));
  }
}
