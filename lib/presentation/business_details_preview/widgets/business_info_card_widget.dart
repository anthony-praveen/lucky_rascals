import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../widgets/custom_icon_widget.dart';

class BusinessInfoCardWidget extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const BusinessInfoCardWidget({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  }) : super(key: key);

  // Helper method to convert IconData to String
  String _getIconName(IconData iconData) {
    // Map common IconData to their string names
    final Map<IconData, String> iconMap = {
      Icons.location_on: 'location_on',
      Icons.phone: 'phone',
      Icons.email: 'email',
      Icons.business: 'business',
      Icons.star: 'star',
      Icons.access_time: 'access_time',
      Icons.local_offer: 'local_offer',
      Icons.shopping_cart: 'shopping_cart',
      Icons.payment: 'payment',
      Icons.receipt: 'receipt',
      Icons.info: 'info',
      Icons.schedule: 'schedule',
      Icons.favorite: 'favorite',
      Icons.share: 'share',
      Icons.directions: 'directions',
      Icons.call: 'call',
      Icons.message: 'message',
      Icons.web: 'web',
      Icons.store: 'store',
      Icons.category: 'category',
    };

    return iconMap[iconData] ?? 'info'; // Default to 'info' if not found
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
        child: Column(children: [
          // Icon
          Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(8)),
              child: CustomIconWidget(
                  iconName: _getIconName(icon), size: 24, color: color)),

          SizedBox(height: 2.h),

          // Value
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 18.sp, fontWeight: FontWeight.bold, color: color)),

          SizedBox(height: 0.5.h),

          // Title
          Text(title,
              style:
                  GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey[600]),
              textAlign: TextAlign.center),
        ]));
  }
}
