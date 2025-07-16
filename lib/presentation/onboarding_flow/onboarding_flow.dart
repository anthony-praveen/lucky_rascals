import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/onboarding_page_widget.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({Key? key}) : super(key: key);

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _currentPage = 0;
  bool _isAnimating = false;

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: 'Scan. Watch. Earn.',
      subtitle:
          'Simply scan QR codes at participating stores to unlock instant rewards',
      description:
          'Transform your everyday shopping into earning opportunities with just a quick scan',
      imagePath:
          'https://images.unsplash.com/photo-1556742400-b5e5850b4d7b?w=500&q=80',
      primaryColor: AppTheme.primaryLight,
      secondaryColor: AppTheme.secondaryLight,
    ),
    OnboardingPageData(
      title: 'Instant UPI Rewards',
      subtitle:
          'Watch short ads and get money directly transferred to your UPI wallet',
      description:
          'No waiting - your earnings land in your account immediately after watching',
      imagePath:
          'https://images.pexels.com/photos/4968639/pexels-photo-4968639.jpeg?w=500&q=80',
      primaryColor: AppTheme.accentLight,
      secondaryColor: AppTheme.secondaryLight,
    ),
    OnboardingPageData(
      title: 'Discover Local Businesses',
      subtitle:
          'Find participating stores and businesses near you on our interactive map',
      description:
          'Support local businesses while earning rewards in your neighborhood',
      imagePath:
          'https://images.pixabay.com/photo/2016/12/30/10/03/app-1939464_1280.jpg',
      primaryColor: AppTheme.secondaryLight,
      secondaryColor: AppTheme.accentLight,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _startAnimation();
  }

  void _startAnimation() {
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_isAnimating) return;

    if (_currentPage < _pages.length - 1) {
      setState(() {
        _isAnimating = true;
      });

      _pageController
          .nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      )
          .then((_) {
        setState(() {
          _isAnimating = false;
        });
      });
    } else {
      _getStarted();
    }
  }

  void _skipOnboarding() {
    HapticFeedback.lightImpact();
    _getStarted();
  }

  void _getStarted() {
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.mobileInput,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              _buildSkipButton(),

              // Page view
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                    HapticFeedback.selectionClick();
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: OnboardingPageWidget(
                          pageData: _pages[index],
                          isActive: index == _currentPage,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Page indicators and navigation
              _buildBottomNavigation(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _skipOnboarding,
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            ),
            child: Text(
              'Skip',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Padding(
      padding: EdgeInsets.all(6.w),
      child: Column(
        children: [
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (index) => _buildPageIndicator(index),
            ),
          ),

          SizedBox(height: 4.h),

          // Navigation button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isAnimating ? null : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: _pages[_currentPage].primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 4.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isAnimating
                  ? SizedBox(
                      width: 5.w,
                      height: 5.w,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _currentPage == _pages.length - 1
                          ? 'Get Started'
                          : 'Next',
                      style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    final isActive = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: 1.w),
      height: 1.h,
      width: isActive ? 8.w : 2.w,
      decoration: BoxDecoration(
        color: isActive ? _pages[_currentPage].primaryColor : Colors.grey[300],
        borderRadius: BorderRadius.circular(1.h),
      ),
    );
  }
}

class OnboardingPageData {
  final String title;
  final String subtitle;
  final String description;
  final String imagePath;
  final Color primaryColor;
  final Color secondaryColor;

  OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.imagePath,
    required this.primaryColor,
    required this.secondaryColor,
  });
}
