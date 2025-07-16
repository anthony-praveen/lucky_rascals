import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/campaign_service.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/business_details_section_widget.dart';
import './widgets/business_hero_widget.dart';
import './widgets/business_info_card_widget.dart';
import './widgets/watch_ad_button_widget.dart';

class BusinessDetailsPreview extends StatefulWidget {
  const BusinessDetailsPreview({Key? key}) : super(key: key);

  @override
  State<BusinessDetailsPreview> createState() => _BusinessDetailsPreviewState();
}

class _BusinessDetailsPreviewState extends State<BusinessDetailsPreview> {
  final CampaignService _campaignService = CampaignService();

  Map<String, dynamic>? _campaignData;
  bool _isLoading = true;
  bool _hasViewedToday = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCampaignData();
    });
  }

  void _loadCampaignData() {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments != null && arguments is Map<String, dynamic>) {
      setState(() {
        _campaignData = arguments;
        _isLoading = false;
      });
      _checkIfViewedToday();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkIfViewedToday() async {
    if (_campaignData == null) return;

    try {
      final hasViewed = await _campaignService
          .hasUserViewedCampaignToday(_campaignData!['campaign_id']);

      if (mounted) {
        setState(() {
          _hasViewedToday = hasViewed;
        });
      }
    } catch (e) {
      debugPrint('Error checking if user viewed campaign today: $e');
    }
  }

  void _onWatchAdPressed() {
    if (_campaignData == null) return;

    // TODO: Navigate to advertisement player
    // Navigator.pushNamed(
    //   context,
    //   AppRoutes.advertisementPlayer,
    //   arguments: _campaignData,
    // );

    // For now, show a success message
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Starting advertisement for ${_campaignData!['business_name']}')));
  }

  void _onSharePressed() {
    if (_campaignData == null) return;

    // TODO: Implement sharing functionality
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Share functionality coming soon!'),
        backgroundColor: Colors.orange));
  }

  void _onBookmarkPressed() {
    // TODO: Implement bookmark functionality
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Bookmark functionality coming soon!'),
        backgroundColor: Colors.blue));
  }

  void _onDirectionsPressed() {
    if (_campaignData == null || _campaignData!['location'] == null) return;

    // TODO: Implement directions functionality
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Opening directions to ${_campaignData!['location']}'),
        backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _campaignData == null
                ? _buildErrorState()
                : _buildContent());
  }

  Widget _buildErrorState() {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      CustomIconWidget(iconName: 'error', size: 64, color: Colors.grey),
      SizedBox(height: 2.h),
      Text('Business data not available',
          style: GoogleFonts.inter(fontSize: 16.sp, color: Colors.grey)),
      SizedBox(height: 2.h),
      ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Go Back')),
    ]));
  }

  Widget _buildContent() {
    return CustomScrollView(slivers: [
      // App bar with back button
      SliverAppBar(
          expandedHeight: 0,
          floating: false,
          pinned: true,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.black)),
          actions: [
            IconButton(
                onPressed: _onSharePressed,
                icon: const Icon(Icons.share, color: Colors.black)),
            IconButton(
                onPressed: _onBookmarkPressed,
                icon: const Icon(Icons.bookmark_border, color: Colors.black)),
          ]),

      // Business hero section
      SliverToBoxAdapter(
          child: BusinessHeroWidget(
              businessName:
                  _campaignData!['business_name'] ?? 'Unknown Business',
              campaignName: _campaignData!['campaign_name'] ?? 'Special Offer',
              location: _campaignData!['location'] ?? 'Location not available',
              imageUrl: _campaignData!['ad_thumbnail_url'])),

      // Business info cards
      SliverToBoxAdapter(
          child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(children: [
                Expanded(
                    child: BusinessInfoCardWidget(
                        title: 'Reward Amount',
                        value: '₹${_campaignData!['reward_amount'] ?? 0}',
                        icon: Icons.currency_rupee,
                        color: Colors.green)),
                SizedBox(width: 3.w),
                Expanded(
                    child: BusinessInfoCardWidget(
                        title: 'Ad Duration',
                        value:
                            '${_campaignData!['ad_duration'] ?? _campaignData!['min_watch_duration'] ?? 10}s',
                        icon: Icons.play_circle_outline,
                        color: Colors.blue)),
              ]))),

      // Watch Ad button
      SliverToBoxAdapter(
          child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: WatchAdButtonWidget(
                  rewardAmount: _campaignData!['reward_amount'] ?? 0,
                  onPressed: _hasViewedToday ? null : _onWatchAdPressed,
                  isDisabled: _hasViewedToday,
                  disabledReason:
                      _hasViewedToday ? 'Already viewed today' : null))),

      // Business details section
      SliverToBoxAdapter(
          child: BusinessDetailsSectionWidget(
              businessName:
                  _campaignData!['business_name'] ?? 'Unknown Business',
              description:
                  _campaignData!['description'] ?? 'No description available',
              location: _campaignData!['location'] ?? 'Location not available',
              onDirectionsPressed: _onDirectionsPressed)),

      // Bottom spacing
      SliverToBoxAdapter(child: SizedBox(height: 4.h)),
    ]);
  }
}
