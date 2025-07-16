import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../onboarding_flow.dart';

class OnboardingPageWidget extends StatefulWidget {
  final OnboardingPageData pageData;
  final bool isActive;

  const OnboardingPageWidget({
    Key? key,
    required this.pageData,
    required this.isActive,
  }) : super(key: key);

  @override
  State<OnboardingPageWidget> createState() => _OnboardingPageWidgetState();
}

class _OnboardingPageWidgetState extends State<OnboardingPageWidget>
    with TickerProviderStateMixin {
  late AnimationController _imageController;
  late AnimationController _textController;
  late Animation<double> _imageScaleAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _imageController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _imageScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _imageController,
      curve: Curves.elasticOut,
    ));

    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));

    if (widget.isActive) {
      _startAnimations();
    }
  }

  void _startAnimations() {
    _imageController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _textController.forward();
    });
  }

  @override
  void didUpdateWidget(OnboardingPageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _startAnimations();
    }
  }

  @override
  void dispose() {
    _imageController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            widget.pageData.primaryColor.withValues(alpha: 0.05),
            Colors.white,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.w),
        child: Column(
          children: [
            SizedBox(height: 4.h),

            // Animated image section
            _buildImageSection(),

            SizedBox(height: 6.h),

            // Animated text content
            _buildTextContent(),

            SizedBox(height: 4.h),

            // Feature highlights
            _buildFeatureHighlights(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return AnimatedBuilder(
      animation: _imageScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _imageScaleAnimation.value,
          child: Container(
            width: 70.w,
            height: 35.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: widget.pageData.primaryColor.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CachedNetworkImage(
                imageUrl: widget.pageData.imagePath,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
                      color: widget.pageData.primaryColor,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: CustomIconWidget(
                      iconName: 'image',
                      color: Colors.grey[400]!,
                      size: 12.w,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextContent() {
    return FadeTransition(
      opacity: _textFadeAnimation,
      child: SlideTransition(
        position: _textSlideAnimation,
        child: Column(
          children: [
            // Title
            Text(
              widget.pageData.title,
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: widget.pageData.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 2.h),

            // Subtitle
            Text(
              widget.pageData.subtitle,
              style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 1.h),

            // Description
            Text(
              widget.pageData.description,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureHighlights() {
    final highlights = _getHighlightsForPage();

    return FadeTransition(
      opacity: _textFadeAnimation,
      child: Column(
        children: highlights.map((highlight) {
          return Padding(
            padding: EdgeInsets.only(bottom: 2.h),
            child: Row(
              children: [
                Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    color: widget.pageData.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4.w),
                  ),
                  child: Center(
                    child: CustomIconWidget(
                      iconName: highlight.icon,
                      color: widget.pageData.primaryColor,
                      size: 4.w,
                    ),
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    highlight.text,
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  List<FeatureHighlight> _getHighlightsForPage() {
    switch (widget.pageData.title) {
      case 'Scan. Watch. Earn.':
        return [
          FeatureHighlight(
            icon: 'qr_code_scanner',
            text: 'Quick QR code scanning with your camera',
          ),
          FeatureHighlight(
            icon: 'play_circle',
            text: 'Short, engaging video advertisements',
          ),
          FeatureHighlight(
            icon: 'account_balance_wallet',
            text: 'Instant earnings with every scan',
          ),
        ];
      case 'Instant UPI Rewards':
        return [
          FeatureHighlight(
            icon: 'payment',
            text: 'Direct UPI transfers to your wallet',
          ),
          FeatureHighlight(
            icon: 'timer',
            text: 'No waiting periods or minimum amounts',
          ),
          FeatureHighlight(
            icon: 'security',
            text: 'Secure and verified transactions',
          ),
        ];
      case 'Discover Local Businesses':
        return [
          FeatureHighlight(
            icon: 'location_on',
            text: 'Find nearby participating stores',
          ),
          FeatureHighlight(
            icon: 'store',
            text: 'Support local businesses in your area',
          ),
          FeatureHighlight(
            icon: 'trending_up',
            text: 'Earn more with frequent visits',
          ),
        ];
      default:
        return [];
    }
  }
}

class FeatureHighlight {
  final String icon;
  final String text;

  FeatureHighlight({
    required this.icon,
    required this.text,
  });
}
