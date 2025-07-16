import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class OtpInputWidget extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final bool hasError;
  final bool isVerifying;
  final Function(String, int) onChanged;
  final Function(int) onBackspace;

  const OtpInputWidget({
    Key? key,
    required this.controllers,
    required this.focusNodes,
    required this.hasError,
    required this.isVerifying,
    required this.onChanged,
    required this.onBackspace,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (index) {
            return _buildOtpBox(index);
          }),
        ),
        if (isVerifying)
          Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 4.w,
                  height: 4.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.lightTheme.primaryColor,
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Text(
                  'Verifying...',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildOtpBox(int index) {
    final isComplete = controllers[index].text.isNotEmpty;
    final isFocused = focusNodes[index].hasFocus;

    return Container(
      width: 12.w,
      height: 12.w,
      decoration: BoxDecoration(
        border: Border.all(
          color: hasError
              ? Colors.red
              : isComplete
                  ? Colors.green
                  : isFocused
                      ? AppTheme.lightTheme.primaryColor
                      : Colors.grey[300]!,
          width: hasError || isComplete || isFocused ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: hasError
            ? Colors.red[50]
            : isComplete
                ? Colors.green[50]
                : Colors.white,
      ),
      child: Stack(
        children: [
          // Text field
          TextFormField(
            controller: controllers[index],
            focusNode: focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            enabled: !isVerifying,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: hasError
                  ? Colors.red
                  : isComplete
                      ? Colors.green
                      : Colors.black,
            ),
            decoration: InputDecoration(
              counterText: '',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (value) {
              if (value.isNotEmpty) {
                onChanged(value, index);
              }
            },
            onFieldSubmitted: (value) {
              if (value.isNotEmpty && index < 5) {
                focusNodes[index + 1].requestFocus();
              }
            },
          ),

          // Custom backspace handling
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                if (!focusNodes[index].hasFocus) {
                  focusNodes[index].requestFocus();
                }
              },
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),

          // Success checkmark
          if (isComplete && !hasError && !isVerifying)
            Positioned(
              top: 1.w,
              right: 1.w,
              child: Container(
                width: 4.w,
                height: 4.w,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 2.5.w,
                ),
              ),
            ),

          // Error indicator
          if (hasError && isComplete)
            Positioned(
              top: 1.w,
              right: 1.w,
              child: Container(
                width: 4.w,
                height: 4.w,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 2.5.w,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class OtpInputFormatter extends TextInputFormatter {
  final Function(int) onBackspace;
  final int index;

  OtpInputFormatter({required this.onBackspace, required this.index});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Handle backspace
    if (newValue.text.isEmpty && oldValue.text.isNotEmpty) {
      onBackspace(index);
    }

    return newValue;
  }
}
