import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../widgets/custom_icon_widget.dart';

class NearbyBusinessesCarouselWidget extends StatelessWidget {
  final List<Map<String, dynamic>> businesses;
  final Function(Map<String, dynamic>) onBusinessTapped;

  const NearbyBusinessesCarouselWidget({
    Key? key,
    required this.businesses,
    required this.onBusinessTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (businesses.isEmpty) {
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        CustomIconWidget(iconName: 'business', size: 32, color: Colors.grey),
        SizedBox(height: 1.h),
        Text('No nearby businesses found',
            style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.grey)),
      ]));
    }

    return SizedBox(
        height: 15.h,
        child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            itemCount: businesses.length,
            itemBuilder: (context, index) {
              final business = businesses[index];
              final store = business['stores'] ?? {};

              return Container(
                  width: 70.w,
                  margin: EdgeInsets.only(right: 3.w),
                  child: _buildBusinessCard(business, store));
            }));
  }

  Widget _buildBusinessCard(
      Map<String, dynamic> business, Map<String, dynamic> store) {
    return GestureDetector(
        onTap: () => onBusinessTapped(business),
        child: Container(
            decoration: BoxDecoration(
                color: Colors.white.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.white.withAlpha(51), width: 1)),
            child: Padding(
                padding: EdgeInsets.all(3.w),
                child: Row(children: [
                  // Business logo/image
                  Container(
                      width: 12.w,
                      height: 12.w,
                      decoration:
                          BoxDecoration(borderRadius: BorderRadius.circular(8)),
                      child: CustomIconWidget(iconName: 'store', size: 24)),

                  SizedBox(width: 3.w),

                  // Business details
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                        Text(store['name'] ?? 'Unknown Business',
                            style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        SizedBox(height: 0.5.h),
                        Text(business['name'] ?? 'Special Offer',
                            style: GoogleFonts.inter(
                                fontSize: 12.sp, color: Colors.grey[300]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        SizedBox(height: 0.5.h),
                        Row(children: [
                          CustomIconWidget(
                              iconName: 'location',
                              size: 12,
                              color: Colors.grey[400]),
                          SizedBox(width: 1.w),
                          Expanded(
                              child: Text(
                                  store['location'] ?? 'Location not available',
                                  style: GoogleFonts.inter(
                                      fontSize: 11.sp, color: Colors.grey[400]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)),
                        ]),
                      ])),

                  // Reward amount
                  Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 2.w, vertical: 0.5.h),
                      decoration:
                          BoxDecoration(borderRadius: BorderRadius.circular(8)),
                      child: Text('₹${business['reward_amount'] ?? 0}',
                          style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white))),
                ]))));
  }
}
