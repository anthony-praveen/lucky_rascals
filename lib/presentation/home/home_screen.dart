import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../services/store_service.dart';
import './widgets/home_header_widget.dart';
import './widgets/nearby_stores_widget.dart';
import './widgets/quick_actions_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final StoreService _storeService = StoreService();

  bool _isLoading = true;
  Map<String, dynamic>? _userProfile;
  List<dynamic> _nearbyStores = [];

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load user profile and nearby stores in parallel
      final results = await Future.wait([
        _authService.getUserProfile(),
        _storeService.getActiveStores(),
      ]);

      if (mounted) {
        setState(() {
          _userProfile = results[0] as Map<String, dynamic>?;
          _nearbyStores = results[1] as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $error')),
        );
      }
    }
  }

  void _navigateToQRScanner() {
    Navigator.pushNamed(context, '/qr-scanner');
  }

  void _navigateToEarnings() {
    Navigator.pushNamed(context, '/earnings');
  }

  void _navigateToProfile() {
    Navigator.pushNamed(context, '/profile');
  }

  Future<void> _handleLogout() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.mobileInput);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadHomeData,
            child: _isLoading
                ? _buildLoadingState()
                : SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        // Header with user info and earnings
                        HomeHeaderWidget(
                          userProfile: _userProfile,
                          onProfileTap: _navigateToProfile,
                          onLogout: _handleLogout,
                        ),

                        SizedBox(height: 2.h),

                        // Quick actions
                        QuickActionsWidget(
                          onScanQR: _navigateToQRScanner,
                          onViewEarnings: _navigateToEarnings,
                        ),

                        SizedBox(height: 3.h),

                        // Nearby stores
                        NearbyStoresWidget(
                          stores: _nearbyStores,
                          onStoreSelected: (store) {
                            // Navigate to store details or start scanning
                            _navigateToQRScanner();
                          },
                        ),

                        SizedBox(height: 2.h),

                        // How it works section
                        _buildHowItWorksSection(),

                        SizedBox(height: 2.h),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              AppTheme.lightTheme.primaryColor,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Loading Lucky Rascals...',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Row(
            children: [
              CustomIconWidget(
                iconName: 'lightbulb',
                color: AppTheme.lightTheme.primaryColor,
                size: 6.w,
              ),
              SizedBox(width: 3.w),
              Text(
                'How It Works',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          _buildHowItWorksStep(
            step: '1',
            title: 'Scan QR Code',
            description: 'Find and scan QR codes at partner stores',
            iconName: 'qr_code_scanner',
          ),
          SizedBox(height: 2.h),
          _buildHowItWorksStep(
            step: '2',
            title: 'Watch Ad',
            description: 'Watch a short video ad (minimum 10 seconds)',
            iconName: 'play_circle_filled',
          ),
          SizedBox(height: 2.h),
          _buildHowItWorksStep(
            step: '3',
            title: 'Earn Money',
            description: 'Get instant cash rewards in your UPI wallet',
            iconName: 'account_balance_wallet',
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksStep({
    required String step,
    required String title,
    required String description,
    required String iconName,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.primaryColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(width: 4.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CustomIconWidget(
                    iconName: iconName,
                    color: AppTheme.lightTheme.primaryColor,
                    size: 5.w,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    title,
                    style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 0.5.h),
              Text(
                description,
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
