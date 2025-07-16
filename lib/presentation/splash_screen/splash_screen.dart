import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late AnimationController _loadingAnimationController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _loadingAnimation;

  bool _showRetryOption = false;
  bool _isInitializing = true;
  String _statusMessage = "Initializing...";

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    // Logo animation controller
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Loading animation controller
    _loadingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();

    // Logo scale animation
    _logoScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.elasticOut,
    ));

    // Logo fade animation
    _logoFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.easeInOut,
    ));

    // Loading animation
    _loadingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _loadingAnimationController,
      curve: Curves.easeInOut,
    ));

    // Start logo animation
    _logoAnimationController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      // Simulate initialization tasks
      await _performInitializationTasks();

      if (mounted) {
        // Navigate to next screen after successful initialization
        await Future.delayed(const Duration(milliseconds: 500));
        _navigateToNextScreen();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _showRetryOption = true;
          _statusMessage = "Failed to initialize. Please try again.";
        });

        // Auto-retry after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted && _showRetryOption) {
            _retryInitialization();
          }
        });
      }
    }
  }

  Future<void> _performInitializationTasks() async {
    // Simulate checking authentication status
    setState(() {
      _statusMessage = "Checking authentication...";
    });
    await Future.delayed(const Duration(milliseconds: 800));

    // Simulate loading user preferences
    setState(() {
      _statusMessage = "Loading preferences...";
    });
    await Future.delayed(const Duration(milliseconds: 600));

    // Simulate initializing camera permissions
    setState(() {
      _statusMessage = "Preparing camera...";
    });
    await Future.delayed(const Duration(milliseconds: 700));

    // Simulate preparing QR scanner
    setState(() {
      _statusMessage = "Initializing QR scanner...";
    });
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _statusMessage = "Ready!";
    });
  }

  void _retryInitialization() {
    setState(() {
      _showRetryOption = false;
      _isInitializing = true;
      _statusMessage = "Retrying...";
    });
    _initializeApp();
  }

  void _navigateToNextScreen() {
    // Simulate navigation logic based on user state
    // For demo purposes, we'll just show a completion message
    setState(() {
      _statusMessage = "Welcome to Lucky Rascals!";
    });

    // In a real app, you would navigate to the appropriate screen:
    // Navigator.pushReplacementNamed(context, '/qr-scanner');
    // Navigator.pushReplacementNamed(context, '/onboarding');
    // Navigator.pushReplacementNamed(context, '/mobile-input');
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _loadingAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppTheme.lightTheme.primaryColor,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.lightTheme.primaryColor,
                AppTheme.lightTheme.primaryColor.withValues(alpha: 0.8),
                AppTheme.lightTheme.colorScheme.primaryContainer,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo section
                Expanded(
                  flex: 3,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _logoAnimationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _logoScaleAnimation.value,
                          child: FadeTransition(
                            opacity: _logoFadeAnimation,
                            child: _buildLogo(),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Status and loading section
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Status message
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        child: Text(
                          _statusMessage,
                          style:
                              AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      SizedBox(height: 3.h),

                      // Loading indicator or retry button
                      _showRetryOption
                          ? _buildRetryButton()
                          : _buildLoadingIndicator(),
                    ],
                  ),
                ),

                // Bottom branding
                Padding(
                  padding: EdgeInsets.only(bottom: 4.h),
                  child: Column(
                    children: [
                      Text(
                        "Scan • Watch • Earn",
                        style:
                            AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        "Made in India 🇮🇳",
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 35.w,
      height: 35.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // QR Code icon
          CustomIconWidget(
            iconName: 'qr_code_scanner',
            color: AppTheme.lightTheme.primaryColor,
            size: 12.w,
          ),

          SizedBox(height: 1.h),

          // App name
          Text(
            "Lucky",
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              color: AppTheme.lightTheme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
            ),
          ),

          Text(
            "Rascals",
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.tertiary,
              fontWeight: FontWeight.w600,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return _isInitializing
        ? Column(
            children: [
              SizedBox(
                width: 8.w,
                height: 8.w,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2.0,
                ),
              ),
              SizedBox(height: 2.h),
              Container(
                width: 60.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: AnimatedBuilder(
                  animation: _loadingAnimation,
                  builder: (context, child) {
                    return FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _loadingAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          )
        : Container();
  }

  Widget _buildRetryButton() {
    return Column(
      children: [
        CustomIconWidget(
          iconName: 'error_outline',
          color: Colors.white,
          size: 8.w,
        ),
        SizedBox(height: 2.h),
        ElevatedButton(
          onPressed: _retryInitialization,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.lightTheme.primaryColor,
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 1.5.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomIconWidget(
                iconName: 'refresh',
                color: AppTheme.lightTheme.primaryColor,
                size: 5.w,
              ),
              SizedBox(width: 2.w),
              Text(
                "Retry",
                style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                  color: AppTheme.lightTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
