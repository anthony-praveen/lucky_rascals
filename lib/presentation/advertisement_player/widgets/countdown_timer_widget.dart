import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class CountdownTimerWidget extends StatefulWidget {
  final int currentTime;
  final int minimumTime;
  final VoidCallback? onTimerCompleted;

  const CountdownTimerWidget({
    Key? key,
    required this.currentTime,
    required this.minimumTime,
    this.onTimerCompleted,
  }) : super(key: key);

  @override
  State<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _colorAnimation = ColorTween(
      begin: Colors.red,
      end: Colors.green,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(CountdownTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.currentTime >= widget.minimumTime &&
        oldWidget.currentTime < widget.minimumTime) {
      // Timer completed
      _animationController.stop();
      widget.onTimerCompleted?.call();
    }
  }

  int get _remainingTime =>
      (widget.minimumTime - widget.currentTime).clamp(0, widget.minimumTime);
  double get _progress => widget.currentTime / widget.minimumTime;
  bool get _isCompleted => widget.currentTime >= widget.minimumTime;

  Color get _timerColor {
    if (_isCompleted) return Colors.green;
    if (_remainingTime <= 3) return Colors.red;
    if (_remainingTime <= 5) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(204),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isCompleted
                  ? Colors.green
                  : _colorAnimation.value ?? Colors.red,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Timer display
              Row(
                children: [
                  Transform.scale(
                    scale: _isCompleted ? 1.0 : _scaleAnimation.value,
                    child: Container(
                      width: 12.w,
                      height: 12.w,
                      decoration: BoxDecoration(
                        color: _timerColor.withAlpha(51),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _timerColor,
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _isCompleted ? '✓' : _remainingTime.toString(),
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            color: _timerColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isCompleted ? 'Reward Unlocked!' : 'Watch for Reward',
                        style:
                            AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        _isCompleted
                            ? 'You can now exit or continue watching'
                            : 'Keep watching for ${_remainingTime}s more',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Progress indicator
              _buildProgressIndicator(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        // Circular progress
        SizedBox(
          width: 10.w,
          height: 10.w,
          child: Stack(
            children: [
              // Background circle
              Container(
                width: 10.w,
                height: 10.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(51),
                ),
              ),
              // Progress circle
              CircularProgressIndicator(
                value: _progress.clamp(0.0, 1.0),
                strokeWidth: 4,
                backgroundColor: Colors.white.withAlpha(51),
                valueColor: AlwaysStoppedAnimation<Color>(_timerColor),
              ),
              // Center icon
              Center(
                child: Icon(
                  _isCompleted ? Icons.check : Icons.timer,
                  color: Colors.white,
                  size: 5.w,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 1.h),
        // Percentage text
        Text(
          '${(_progress * 100).toInt()}%',
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
