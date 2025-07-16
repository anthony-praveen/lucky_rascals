import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../widgets/custom_icon_widget.dart';

class WatchAdButtonWidget extends StatelessWidget {
  final double rewardAmount;
  final VoidCallback? onPressed;
  final bool isDisabled;
  final String? disabledReason;

  const WatchAdButtonWidget({
    Key? key,
    required this.rewardAmount,
    this.onPressed,
    this.isDisabled = false,
    this.disabledReason,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.infinity,
        height: 14.h,
        decoration: BoxDecoration(
            gradient: isDisabled
                ? LinearGradient(
                    colors: [Colors.grey.shade300, Colors.grey.shade400])
                : LinearGradient(colors: [Colors.blue, Colors.blueAccent]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDisabled
                ? null
                : [
                    BoxShadow(blurRadius: 12, offset: const Offset(0, 4)),
                  ]),
        child: Material(
            color: Colors.transparent,
            child: InkWell(
                onTap: isDisabled ? null : onPressed,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Main button content
                          Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Play icon
                                Container(
                                    padding: EdgeInsets.all(2.w),
                                    decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(51),
                                        borderRadius: BorderRadius.circular(8)),
                                    child: CustomIconWidget(
                                        iconName: 'play',
                                        size: 24,
                                        color: Colors.white)),

                                SizedBox(width: 3.w),

                                // Button text
                                Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          isDisabled
                                              ? 'Completed Today'
                                              : 'Watch Ad & Earn',
                                          style: GoogleFonts.inter(
                                              fontSize: 18.sp,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white)),
                                      if (!isDisabled) ...[
                                        SizedBox(height: 0.5.h),
                                        Text(
                                            'Earn ₹${rewardAmount.toStringAsFixed(0)} instantly',
                                            style: GoogleFonts.inter(
                                                fontSize: 14.sp,
                                                color: Colors.white
                                                    .withAlpha(230))),
                                      ],
                                    ]),
                              ]),

                          // Disabled reason
                          if (isDisabled && disabledReason != null) ...[
                            SizedBox(height: 1.h),
                            Text(disabledReason!,
                                style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    color: Colors.white.withAlpha(204)),
                                textAlign: TextAlign.center),
                          ],
                        ])))));
  }
}
