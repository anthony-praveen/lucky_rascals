import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PhoneInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isValid;
  final VoidCallback onChanged;

  const PhoneInputWidget({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.isValid,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<PhoneInputWidget> createState() => _PhoneInputWidgetState();
}

class _PhoneInputWidgetState extends State<PhoneInputWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _borderAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _borderAnimation = Tween<double>(
      begin: 1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _colorAnimation = ColorTween(
      begin: Colors.grey[300],
      end: Colors.green,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(PhoneInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isValid != oldWidget.isValid) {
      if (widget.isValid) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'phone',
                    color: AppTheme.primaryLight,
                    size: 5.w,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Mobile Number',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 2.h),

              // Phone number input with animated border
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _colorAnimation.value ?? Colors.grey[300]!,
                    width: _borderAnimation.value,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    // Country code section
                    Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Flag
                          Container(
                            width: 6.w,
                            height: 4.w,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 0.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '🇮🇳',
                                style: TextStyle(fontSize: 3.w),
                              ),
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            '+91',
                            style: AppTheme.lightTheme.textTheme.bodyLarge
                                ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Phone number input
                    Expanded(
                      child: TextFormField(
                        controller: widget.controller,
                        focusNode: widget.focusNode,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: InputDecoration(
                          hintText: '9876543210',
                          hintStyle:
                              AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[400],
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(4.w),
                        ),
                        style:
                            AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                        onChanged: (value) => widget.onChanged(),
                      ),
                    ),

                    // Validation icon
                    if (widget.controller.text.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(right: 4.w),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: widget.isValid
                              ? Container(
                                  key: const ValueKey('valid'),
                                  padding: EdgeInsets.all(1.w),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                  child: CustomIconWidget(
                                    iconName: 'check',
                                    color: Colors.white,
                                    size: 4.w,
                                  ),
                                )
                              : Container(
                                  key: const ValueKey('invalid'),
                                  padding: EdgeInsets.all(1.w),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: CustomIconWidget(
                                    iconName: 'close',
                                    color: Colors.white,
                                    size: 4.w,
                                  ),
                                ),
                        ),
                      ),
                  ],
                ),
              ),

              // Validation message
              if (widget.controller.text.isNotEmpty && !widget.isValid)
                Padding(
                  padding: EdgeInsets.only(top: 1.h),
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'error',
                        color: Colors.red,
                        size: 4.w,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'Please enter a valid 10-digit mobile number',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),

              if (widget.controller.text.isNotEmpty && widget.isValid)
                Padding(
                  padding: EdgeInsets.only(top: 1.h),
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'check_circle',
                        color: Colors.green,
                        size: 4.w,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'Valid mobile number',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
