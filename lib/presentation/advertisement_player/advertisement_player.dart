import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/advertisement_service.dart';
import '../../services/auth_service.dart';
import './widgets/countdown_timer_widget.dart';
import './widgets/engagement_overlay_widget.dart';
import './widgets/reward_preview_widget.dart';
import './widgets/video_player_widget.dart';

class AdvertisementPlayerScreen extends StatefulWidget {
  const AdvertisementPlayerScreen({Key? key}) : super(key: key);

  @override
  State<AdvertisementPlayerScreen> createState() =>
      _AdvertisementPlayerScreenState();
}

class _AdvertisementPlayerScreenState extends State<AdvertisementPlayerScreen> {
  final AdvertisementService _adService = AdvertisementService();
  final AuthService _authService = AuthService();

  // Screen state
  bool _isLoading = true;
  bool _isInitialized = false;
  bool _canExit = false;
  String? _error;

  // Campaign and user data
  Map<String, dynamic>? _campaignData;
  Map<String, dynamic>? _userProfile;
  String? _currentViewId;

  // Video and timer state
  bool _isVideoPlaying = false;
  bool _isVideoLoaded = false;
  int _currentTime = 0;
  int _totalDuration = 0;
  int _minimumViewDuration = 10;
  double _rewardAmount = 0.0;

  // Engagement tracking
  Timer? _engagementTimer;
  Timer? _progressTimer;
  int _engagementChecks = 0;
  bool _hasCompletedMinimumTime = false;
  bool _rewardEligible = false;
  bool _showRewardPreview = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _setupEngagementTracking();
  }

  @override
  void dispose() {
    _engagementTimer?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get campaign data from route arguments
      final arguments =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (arguments == null || arguments['campaignId'] == null) {
        throw Exception('Campaign ID not provided');
      }

      final campaignId = arguments['campaignId'] as String;

      // Load user profile and campaign data
      final results = await Future.wait([
        _authService.getUserProfile(),
        _adService.getCampaignById(campaignId),
      ]);

      _userProfile = results[0];
      _campaignData = results[1];

      if (_userProfile == null) {
        throw Exception('User not authenticated');
      }

      if (_campaignData == null) {
        throw Exception('Campaign not found');
      }

      // Check if user can view this campaign
      final canView = await _adService.canUserViewCampaign(
        campaignId,
        _userProfile!['id'],
      );

      if (!canView) {
        throw Exception('You have reached the maximum views for this campaign');
      }

      // Extract campaign details
      _minimumViewDuration = _campaignData!['minimum_view_duration'] ?? 10;
      _rewardAmount = (_campaignData!['reward_amount'] ?? 0.0).toDouble();

      // Record view start
      _currentViewId = await _adService.recordAdViewStart(
        campaignId,
        _userProfile!['id'],
      );

      if (_currentViewId == null) {
        throw Exception('Failed to initialize ad tracking');
      }

      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });

      // Start engagement tracking
      _startEngagementTimer();
      _startProgressTimer();
    } catch (error) {
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  void _setupEngagementTracking() {
    // Prevent user from leaving during critical viewing period
    SystemChannels.platform.setMethodCallHandler((call) async {
      if (call.method == 'routeUpdated') {
        if (!_canExit && !_hasCompletedMinimumTime) {
          // Show warning or prevent navigation
          _showExitWarning();
        }
      }
    });
  }

  void _startEngagementTimer() {
    _engagementTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      _performEngagementCheck();
    });
  }

  void _startProgressTimer() {
    _progressTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_isVideoPlaying && _currentTime < _totalDuration) {
        setState(() {
          _currentTime++;
        });

        // Check if minimum viewing time reached
        if (_currentTime >= _minimumViewDuration && !_hasCompletedMinimumTime) {
          setState(() {
            _hasCompletedMinimumTime = true;
            _canExit = true;
          });
          _checkRewardEligibility();
        }

        // Check if video completed
        if (_currentTime >= _totalDuration) {
          _onVideoCompleted();
        }
      }
    });
  }

  void _performEngagementCheck() {
    // Simple engagement check - in production this would be more sophisticated
    if (_isVideoPlaying && mounted) {
      setState(() {
        _engagementChecks++;
      });

      // Simulate attention check every 10 seconds
      if (_engagementChecks % 10 == 0) {
        _showAttentionCheck();
      }
    }
  }

  void _showAttentionCheck() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Attention Check'),
        content: Text('Tap "I\'m Watching" to continue earning rewards'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Continue normal flow
            },
            child: Text('I\'m Watching'),
          ),
        ],
      ),
    );
  }

  void _showExitWarning() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Warning'),
        content: Text(
            'You need to watch at least $_minimumViewDuration seconds to earn rewards. Continue watching?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Continue watching
            },
            child: Text('Continue Watching'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exitWithoutReward();
            },
            child: Text('Exit Without Reward'),
          ),
        ],
      ),
    );
  }

  void _checkRewardEligibility() {
    final completionPercentage =
        _adService.calculateViewingProgress(_currentTime, _totalDuration);
    final isEligible = _adService.isEligibleForReward(
      _currentTime,
      completionPercentage,
      _minimumViewDuration,
    );

    if (isEligible) {
      setState(() {
        _rewardEligible = true;
        _showRewardPreview = true;
      });
    }
  }

  void _onVideoCompleted() {
    _progressTimer?.cancel();
    _engagementTimer?.cancel();

    final completionPercentage =
        _adService.calculateViewingProgress(_currentTime, _totalDuration);

    _processReward(completionPercentage);
  }

  Future<void> _processReward(double completionPercentage) async {
    if (_currentViewId == null ||
        _campaignData == null ||
        _userProfile == null) {
      return;
    }

    try {
      final result = await _adService.recordAdViewCompletion(
        _currentViewId!,
        _campaignData!['id'],
        _userProfile!['id'],
        _currentTime,
        completionPercentage,
      );

      if (result != null &&
          result['reward_earned'] != null &&
          result['reward_earned'] > 0) {
        _showRewardSuccess(result['reward_earned']);
      } else {
        _showCompletionMessage();
      }
    } catch (error) {
      _showError('Failed to process reward: $error');
    }
  }

  void _showRewardSuccess(double rewardAmount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.celebration, color: Colors.green),
            SizedBox(width: 2.w),
            Text('Reward Earned!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Congratulations! You have earned:'),
            SizedBox(height: 2.h),
            Text(
              _adService.formatRewardAmount(rewardAmount),
              style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),
            Text('The reward will be credited to your UPI account shortly.'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _exitToHome();
            },
            child: Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showCompletionMessage() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Video Completed'),
        content: Text(
            'Thank you for watching! You did not meet the minimum requirements for a reward this time.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exitToHome();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () => _initializePlayer(),
        ),
      ),
    );
  }

  void _exitWithoutReward() {
    Navigator.pop(context);
  }

  void _exitToHome() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      (route) => false,
    );
  }

  void _onVideoStateChanged(bool isPlaying, bool isLoaded, int duration) {
    setState(() {
      _isVideoPlaying = isPlaying;
      _isVideoLoaded = isLoaded;
      if (duration > 0) {
        _totalDuration = duration;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_canExit) {
          return true;
        } else {
          _showExitWarning();
          return false;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: SafeArea(
            child: _isLoading
                ? _buildLoadingState()
                : _error != null
                    ? _buildErrorState()
                    : _buildPlayerInterface(),
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
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          SizedBox(height: 3.h),
          Text(
            'Preparing your ad experience...',
            style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 8.w,
          ),
          SizedBox(height: 3.h),
          Text(
            'Error Loading Advertisement',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
            ),
          ),
          SizedBox(height: 2.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Text(
              _error ?? 'Unknown error occurred',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 4.h),
          ElevatedButton(
            onPressed: _initializePlayer,
            child: Text('Retry'),
          ),
          SizedBox(height: 2.h),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Go Back',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerInterface() {
    if (_campaignData == null) {
      return _buildErrorState();
    }

    return Stack(
      children: [
        // Video Player
        VideoPlayerWidget(
          videoUrl: _campaignData!['video_url'],
          onStateChanged: _onVideoStateChanged,
          preventControls: !_hasCompletedMinimumTime,
        ),

        // Countdown Timer Overlay
        if (!_hasCompletedMinimumTime)
          Positioned(
            top: 4.h,
            left: 4.w,
            right: 4.w,
            child: CountdownTimerWidget(
              currentTime: _currentTime,
              minimumTime: _minimumViewDuration,
              onTimerCompleted: () {
                setState(() {
                  _hasCompletedMinimumTime = true;
                  _canExit = true;
                });
                _checkRewardEligibility();
              },
            ),
          ),

        // Reward Preview Panel
        if (_showRewardPreview)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: RewardPreviewWidget(
              rewardAmount: _rewardAmount,
              campaignTitle: _campaignData!['title'],
              onClaimReward: () {
                setState(() {
                  _showRewardPreview = false;
                });
                _onVideoCompleted();
              },
            ),
          ),

        // Engagement Overlay
        EngagementOverlayWidget(
          isVideoPlaying: _isVideoPlaying,
          currentTime: _currentTime,
          totalDuration: _totalDuration,
          canExit: _canExit,
          onExitPressed: _canExit ? _exitToHome : null,
        ),

        // Anti-fraud overlay (prevents recording)
        if (!_hasCompletedMinimumTime)
          Positioned.fill(
            child: Container(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: () {
                  // Prevent tapping through
                },
                behavior: HitTestBehavior.translucent,
              ),
            ),
          ),
      ],
    );
  }
}
