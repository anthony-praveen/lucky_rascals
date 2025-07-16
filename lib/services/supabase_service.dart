import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/supabase_constants.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  SupabaseClient? _client;
  bool _isInitialized = false;
  late final Future<void> _initFuture;

  // Singleton pattern
  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal() {
    _initFuture = _initializeSupabase();
  }

  static const String supabaseUrl = SupabaseConstants.url;
  static const String supabaseAnonKey = SupabaseConstants.anonKey;

  // Internal initialization logic with enhanced error handling
  Future<void> _initializeSupabase() async {
    try {
      // Check if constants are provided
      if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
        debugPrint('Warning: SUPABASE_URL and SUPABASE_ANON_KEY not provided');
        _isInitialized = false;
        return;
      }

      // Validate URL format
      if (!_isValidUrl(supabaseUrl)) {
        debugPrint('Error: Invalid SUPABASE_URL format');
        _isInitialized = false;
        return;
      }

      // Initialize Supabase
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );

      _client = Supabase.instance.client;
      _isInitialized = true;
      debugPrint('Supabase initialized successfully');

      // Test connection
      await _testConnection();
    } catch (error) {
      debugPrint('Supabase initialization failed: $error');
      _isInitialized = false;
      _client = null;
    }
  }

  // Validate URL format
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }

  // Test connection to Supabase
  Future<void> _testConnection() async {
    try {
      if (_client == null) return;

      // Simple connection test
      final response = await _client!.auth.getUser();
      debugPrint('Supabase connection test successful');
    } catch (error) {
      debugPrint('Supabase connection test failed: $error');
    }
  }

  // Client getter with null safety
  Future<SupabaseClient?> get client async {
    try {
      if (!_isInitialized) {
        await _initFuture;
      }
      return _client;
    } catch (error) {
      debugPrint('Error getting Supabase client: $error');
      return null;
    }
  }

  // Check if Supabase is properly configured
  bool get isConfigured => _isInitialized && _client != null;

  // Get configuration status
  Map<String, dynamic> get configurationStatus {
    return {
      'is_initialized': _isInitialized,
      'has_client': _client != null,
      'has_url': supabaseUrl.isNotEmpty,
      'has_anon_key': supabaseAnonKey.isNotEmpty,
    };
  }

  // Manual initialization retry
  Future<bool> retryInitialization() async {
    try {
      _isInitialized = false;
      _client = null;
      await _initializeSupabase();
      return _isInitialized;
    } catch (error) {
      debugPrint('Retry initialization failed: $error');
      return false;
    }
  }

  // Dispose resources
  void dispose() {
    _client = null;
    _isInitialized = false;
  }
}
