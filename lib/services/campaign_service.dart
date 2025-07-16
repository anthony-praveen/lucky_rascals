import 'package:flutter/foundation.dart';

import './supabase_service.dart';

class CampaignService {
  static final CampaignService _instance = CampaignService._internal();
  factory CampaignService() => _instance;
  CampaignService._internal();

  final SupabaseService _supabaseService = SupabaseService();

  // Get campaign details by QR code
  Future<Map<String, dynamic>?> getCampaignByQRCode(String qrCode) async {
    try {
      final client = await _supabaseService.client;
      if (client == null) {
        throw Exception('Supabase client not initialized');
      }

      // Call the database function to get campaign details
      final response = await client
          .rpc('get_campaigns_by_qr_code', params: {'qr_code_value': qrCode});

      if (response == null || response.isEmpty) {
        return null;
      }

      final campaignData = response.first;
      return {
        'campaign_id': campaignData['campaign_id'],
        'business_name': campaignData['business_name'],
        'campaign_name': campaignData['campaign_name'],
        'description': campaignData['description'],
        'reward_amount': campaignData['reward_amount'],
        'min_watch_duration': campaignData['min_watch_duration'],
        'location': campaignData['location'],
        'ad_content_url': campaignData['ad_content_url'],
        'ad_duration': campaignData['ad_duration'],
        'ad_thumbnail_url': campaignData['ad_thumbnail_url'],
      };
    } catch (e) {
      debugPrint('Error fetching campaign by QR code: $e');
      return null;
    }
  }

  // Get nearby active campaigns
  Future<List<Map<String, dynamic>>> getNearbyBusinesses() async {
    try {
      final client = await _supabaseService.client;
      if (client == null) {
        throw Exception('Supabase client not initialized');
      }

      final response = await client
          .from('business_campaigns')
          .select('''
            id,
            name,
            description,
            reward_amount,
            min_watch_duration,
            business_id,
            stores!inner(
              id,
              name,
              location,
              qr_code
            )
          ''')
          .eq('status', 'active')
          .gt('budget_remaining', 0)
          .order('created_at', ascending: false)
          .limit(10);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching nearby businesses: $e');
      return [];
    }
  }

  // Record ad view
  Future<bool> recordAdView({
    required String campaignId,
    required String adId,
    required int watchDuration,
    required bool completed,
    required double rewardEarned,
  }) async {
    try {
      final client = await _supabaseService.client;
      if (client == null) {
        throw Exception('Supabase client not initialized');
      }

      final user = client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await client.from('ad_views').insert({
        'user_id': user.id,
        'campaign_id': campaignId,
        'ad_id': adId,
        'watch_duration': watchDuration,
        'completed': completed,
        'reward_earned': rewardEarned,
        'reward_status': completed ? 'completed' : 'pending',
      }).select();

      return response.isNotEmpty;
    } catch (e) {
      debugPrint('Error recording ad view: $e');
      return false;
    }
  }

  // Get user's ad viewing history
  Future<List<Map<String, dynamic>>> getUserAdHistory() async {
    try {
      final client = await _supabaseService.client;
      if (client == null) {
        throw Exception('Supabase client not initialized');
      }

      final user = client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await client
          .from('ad_views')
          .select('''
            id,
            watch_duration,
            completed,
            reward_earned,
            reward_status,
            created_at,
            business_campaigns!inner(
              name,
              description,
              stores!inner(
                name,
                location
              )
            )
          ''')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(20);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching user ad history: $e');
      return [];
    }
  }

  // Get business analytics
  Future<Map<String, dynamic>?> getBusinessAnalytics(String businessId) async {
    try {
      final client = await _supabaseService.client;
      if (client == null) {
        throw Exception('Supabase client not initialized');
      }

      final response = await client
          .from('business_analytics')
          .select('''
            total_views,
            total_completed_views,
            total_rewards_paid,
            date
          ''')
          .eq('business_id', businessId)
          .order('date', ascending: false)
          .limit(30);

      if (response.isEmpty) return null;

      // Calculate totals
      int totalViews = 0;
      int totalCompletedViews = 0;
      double totalRewardsPaid = 0.0;

      for (final record in response) {
        totalViews += (record['total_views'] as int? ?? 0);
        totalCompletedViews += (record['total_completed_views'] as int? ?? 0);
        totalRewardsPaid +=
            (record['total_rewards_paid'] as num? ?? 0.0).toDouble();
      }

      return {
        'total_views': totalViews,
        'total_completed_views': totalCompletedViews,
        'total_rewards_paid': totalRewardsPaid,
        'completion_rate':
            totalViews > 0 ? (totalCompletedViews / totalViews * 100) : 0.0,
        'daily_data': response,
      };
    } catch (e) {
      debugPrint('Error fetching business analytics: $e');
      return null;
    }
  }

  // Check if user has already viewed a campaign today
  Future<bool> hasUserViewedCampaignToday(String campaignId) async {
    try {
      final client = await _supabaseService.client;
      if (client == null) {
        throw Exception('Supabase client not initialized');
      }

      final user = client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final today = DateTime.now().toIso8601String().split('T')[0];
      final response = await client
          .from('ad_views')
          .select('id')
          .eq('user_id', user.id)
          .eq('campaign_id', campaignId)
          .gte('created_at', '${today}T00:00:00')
          .lte('created_at', '${today}T23:59:59')
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking user campaign view: $e');
      return false;
    }
  }
}
