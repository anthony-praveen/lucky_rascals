import 'package:flutter/foundation.dart';

import './supabase_service.dart';

class AdvertisementService {
  final SupabaseService _supabaseService = SupabaseService();

  /// Get active campaigns for a specific store
  Future<List<Map<String, dynamic>>> getActiveCampaigns(
      {String? storeId}) async {
    try {
      final client = await _supabaseService.client;
      if (client == null) {
        throw Exception('Supabase client not initialized');
      }

      var query = client
          .from('ad_campaigns')
          .select('*, stores(name, location)')
          .eq('status', 'active');

      if (storeId != null) {
        query = query.eq('store_id', storeId);
      }

      final response = await query
          .gte('end_date', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('Error fetching active campaigns: $error');
      return [];
    }
  }

  /// Get campaign details by ID
  Future<Map<String, dynamic>?> getCampaignById(String campaignId) async {
    try {
      final client = await _supabaseService.client;
      if (client == null) {
        throw Exception('Supabase client not initialized');
      }

      final response = await client
          .from('ad_campaigns')
          .select('*, stores(name, location)')
          .eq('id', campaignId)
          .single();

      return response;
    } catch (error) {
      debugPrint('Error fetching campaign: $error');
      return null;
    }
  }

  /// Check if user can view a campaign (hasn't exceeded max views)
  Future<bool> canUserViewCampaign(String campaignId, String userId) async {
    try {
      final client = await _supabaseService.client;
      if (client == null) {
        throw Exception('Supabase client not initialized');
      }

      // Get campaign details
      final campaignResponse = await client
          .from('ad_campaigns')
          .select('max_views_per_user')
          .eq('id', campaignId)
          .single();

      final maxViews = campaignResponse['max_views_per_user'] as int;

      // Count user's views for this campaign
      final userViewsResponse = await client
          .from('ad_views')
          .select('id')
          .eq('campaign_id', campaignId)
          .eq('user_id', userId)
          .count();

      final userViews = userViewsResponse.count ?? 0;

      return userViews < maxViews;
    } catch (error) {
      debugPrint('Error checking campaign eligibility: $error');
      return false;
    }
  }

  /// Record advertisement view start
  Future<String?> recordAdViewStart(String campaignId, String userId) async {
    try {
      final client = await _supabaseService.client;
      if (client == null) {
        throw Exception('Supabase client not initialized');
      }

      final response = await client
          .from('ad_views')
          .insert({
            'campaign_id': campaignId,
            'user_id': userId,
            'viewing_status': 'started',
            'started_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return response['id'] as String;
    } catch (error) {
      debugPrint('Error recording ad view start: $error');
      return null;
    }
  }

  /// Record advertisement view completion and process reward
  Future<Map<String, dynamic>?> recordAdViewCompletion(
    String viewId,
    String campaignId,
    String userId,
    int durationSeconds,
    double completionPercentage,
  ) async {
    try {
      final client = await _supabaseService.client;
      if (client == null) {
        throw Exception('Supabase client not initialized');
      }

      // Call the stored procedure for completion
      final response = await client.rpc('record_ad_view_completion', params: {
        'campaign_uuid': campaignId,
        'user_uuid': userId,
        'duration_seconds': durationSeconds,
        'completion_percent': completionPercentage,
      });

      // Update the existing view record
      await client.from('ad_views').update({
        'view_duration': durationSeconds,
        'completion_percentage': completionPercentage,
        'completed_at': DateTime.now().toIso8601String(),
      }).eq('id', viewId);

      // Get updated view with reward info
      final updatedView = await client
          .from('ad_views')
          .select('*, ad_campaigns(reward_amount, minimum_view_duration)')
          .eq('id', viewId)
          .single();

      return updatedView;
    } catch (error) {
      debugPrint('Error recording ad view completion: $error');
      return null;
    }
  }

  /// Get user's ad viewing history
  Future<List<Map<String, dynamic>>> getUserAdHistory(String userId) async {
    try {
      final client = await _supabaseService.client;
      if (client == null) {
        throw Exception('Supabase client not initialized');
      }

      final response = await client
          .from('ad_views')
          .select('*, ad_campaigns(title, reward_amount), stores(name)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('Error fetching user ad history: $error');
      return [];
    }
  }

  /// Get user's reward transactions
  Future<List<Map<String, dynamic>>> getUserRewardTransactions(
      String userId) async {
    try {
      final client = await _supabaseService.client;
      if (client == null) {
        throw Exception('Supabase client not initialized');
      }

      final response = await client
          .from('reward_transactions')
          .select('*, ad_views(*, ad_campaigns(title))')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('Error fetching reward transactions: $error');
      return [];
    }
  }

  /// Get campaign analytics for business users
  Future<Map<String, dynamic>> getCampaignAnalytics(String campaignId) async {
    try {
      final client = await _supabaseService.client;
      if (client == null) {
        throw Exception('Supabase client not initialized');
      }

      // Get campaign details
      final campaignResponse = await client
          .from('ad_campaigns')
          .select('*')
          .eq('id', campaignId)
          .single();

      // Get view statistics
      final viewStats = await client
          .from('ad_views')
          .select('viewing_status, reward_earned')
          .eq('campaign_id', campaignId);

      // Calculate analytics
      final totalViews = viewStats.length;
      final completedViews = viewStats
          .where((v) =>
              v['viewing_status'] == 'completed' ||
              v['viewing_status'] == 'rewarded')
          .length;
      final rewardedViews =
          viewStats.where((v) => v['viewing_status'] == 'rewarded').length;
      final totalRewards = viewStats.fold<double>(
          0, (sum, v) => sum + (v['reward_earned'] as double? ?? 0.0));

      return {
        'campaign': campaignResponse,
        'total_views': totalViews,
        'completed_views': completedViews,
        'rewarded_views': rewardedViews,
        'completion_rate':
            totalViews > 0 ? (completedViews / totalViews * 100) : 0.0,
        'reward_rate':
            totalViews > 0 ? (rewardedViews / totalViews * 100) : 0.0,
        'total_rewards_paid': totalRewards,
        'average_reward':
            rewardedViews > 0 ? (totalRewards / rewardedViews) : 0.0,
      };
    } catch (error) {
      debugPrint('Error fetching campaign analytics: $error');
      return {};
    }
  }

  /// Update campaign status
  Future<bool> updateCampaignStatus(String campaignId, String status) async {
    try {
      final client = await _supabaseService.client;
      if (client == null) {
        throw Exception('Supabase client not initialized');
      }

      await client.from('ad_campaigns').update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', campaignId);

      return true;
    } catch (error) {
      debugPrint('Error updating campaign status: $error');
      return false;
    }
  }

  /// Calculate reward eligibility based on viewing criteria
  bool isEligibleForReward(
      int viewDuration, double completionPercentage, int minimumDuration) {
    return viewDuration >= minimumDuration && completionPercentage >= 80.0;
  }

  /// Format reward amount for display
  String formatRewardAmount(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  /// Get viewing progress percentage
  double calculateViewingProgress(int currentTime, int totalDuration) {
    if (totalDuration <= 0) return 0.0;
    return (currentTime / totalDuration * 100).clamp(0.0, 100.0);
  }
}
