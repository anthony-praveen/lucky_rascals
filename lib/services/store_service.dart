import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

class StoreService {
  static final StoreService _instance = StoreService._internal();
  factory StoreService() => _instance;
  StoreService._internal();

  Future<SupabaseClient> get client async => await SupabaseService().client;

  // Get store by QR code
  Future<Map<String, dynamic>?> getStoreByQRCode(String qrCode) async {
    try {
      final supabase = await client;

      final response = await supabase
          .from('stores')
          .select()
          .eq('qr_code', qrCode)
          .eq('is_active', true)
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to get store: $error');
    }
  }

  // Get all active stores
  Future<List<dynamic>> getActiveStores() async {
    try {
      final supabase = await client;

      final response = await supabase
          .from('stores')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return response;
    } catch (error) {
      throw Exception('Failed to get stores: $error');
    }
  }

  // Get nearby stores (mock implementation)
  Future<List<dynamic>> getNearbyStores({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    try {
      // TODO: Implement geolocation-based filtering
      // For now, return all active stores
      return await getActiveStores();
    } catch (error) {
      throw Exception('Failed to get nearby stores: $error');
    }
  }

  // Validate QR code format
  bool isValidQRCode(String qrCode) {
    // Check if QR code matches expected format
    return qrCode.isNotEmpty && qrCode.startsWith('QR_');
  }
}
