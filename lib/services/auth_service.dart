import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  Future<SupabaseClient> get client async => await SupabaseService().client;

  // Register user with phone number
  Future<AuthResponse> signUpWithPhone({
    required String phoneNumber,
    required String password,
    String? upiId,
    bool whatsappEnabled = false,
  }) async {
    try {
      final supabase = await client;

      final response = await supabase.auth.signUp(
        phone: phoneNumber,
        password: password,
        data: {
          'upi_id': upiId,
          'whatsapp_enabled': whatsappEnabled,
        },
      );

      return response;
    } catch (error) {
      throw Exception('Sign-up failed: $error');
    }
  }

  // Sign in with phone number
  Future<AuthResponse> signInWithPhone({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final supabase = await client;

      final response = await supabase.auth.signInWithPassword(
        phone: phoneNumber,
        password: password,
      );

      return response;
    } catch (error) {
      throw Exception('Sign-in failed: $error');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      final supabase = await client;
      await supabase.auth.signOut();
    } catch (error) {
      throw Exception('Sign-out failed: $error');
    }
  }

  // Get current user
  User? get currentUser => Supabase.instance.client.auth.currentUser;

  // Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges =>
      Supabase.instance.client.auth.onAuthStateChange;

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final supabase = await client;
      final user = currentUser;

      if (user == null) return null;

      final response = await supabase
          .from('user_profiles')
          .select()
          .eq('id', user.id)
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to get user profile: $error');
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? upiId,
    bool? whatsappEnabled,
    String? phoneNumber,
  }) async {
    try {
      final supabase = await client;
      final user = currentUser;

      if (user == null) throw Exception('User not authenticated');

      final updates = <String, dynamic>{};
      if (upiId != null) updates['upi_id'] = upiId;
      if (whatsappEnabled != null)
        updates['whatsapp_enabled'] = whatsappEnabled;
      if (phoneNumber != null) updates['phone_number'] = phoneNumber;

      if (updates.isNotEmpty) {
        updates['updated_at'] = DateTime.now().toIso8601String();

        await supabase.from('user_profiles').update(updates).eq('id', user.id);
      }
    } catch (error) {
      throw Exception('Failed to update user profile: $error');
    }
  }
}
