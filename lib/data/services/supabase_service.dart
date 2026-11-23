import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../models/battery_model.dart';
import '../models/company_model.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient? _client;
  bool _isConfigured = false;
  bool _isSignedIn = false;

  bool get isConfigured => _isConfigured;
  bool get isSignedIn => _isSignedIn;
  SupabaseClient? get client => _client;

  String? get currentUserId => _client?.auth.currentUser?.id;

  /// Initializes Supabase if valid URL and Anon Key are present.
  Future<void> init() async {
    final url = dotenv.env['SUPABASE_URL']?.trim() ?? '';
    final anonKey = dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '';

    if (url.isEmpty ||
        anonKey.isEmpty ||
        url.contains('your-project') ||
        url.contains('placeholder')) {
      debugPrint('Supabase not configured or using placeholders. Running in local-first offline mode.');
      _isConfigured = false;
      return;
    }

    try {
      await Supabase.initialize(
        url: url,
        publishableKey: anonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      _client = Supabase.instance.client;
      _isConfigured = true;
      debugPrint('Supabase initialized successfully.');

      // Attempt silent background sign-in
      await silentSignIn();
    } catch (e) {
      debugPrint('Error initializing Supabase: $e');
      _isConfigured = false;
    }
  }

  /// Performs silent background sign-in using email and password from .env.
  /// If session is already active, avoids redundant sign-in.
  Future<bool> silentSignIn() async {
    if (!_isConfigured || _client == null) return false;

    // Check if session already exists and is valid
    if (_client!.auth.currentSession != null) {
      _isSignedIn = true;
      debugPrint('Active Supabase session restored for: ${_client!.auth.currentUser?.email}');
      return true;
    }

    final email = dotenv.env['SUPABASE_USER_EMAIL']?.trim() ?? '';
    final password = dotenv.env['SUPABASE_USER_PASSWORD']?.trim() ?? '';

    if (email.isEmpty || password.isEmpty || email == 'user@example.com') {
      debugPrint('No valid user credentials in .env. Working with local cache.');
      return false;
    }

    try {
      final response = await _client!.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user != null) {
        _isSignedIn = true;
        debugPrint('Silent background sign-in succeeded for $email');
        return true;
      }
    } catch (e) {
      debugPrint('Silent background sign-in failed: $e. Local cache remains active.');
      _isSignedIn = false;
    }
    return false;
  }

  // ==========================================
  // Companies Remote Operations
  // ==========================================
  Future<List<CompanyModel>> fetchCompanies() async {
    if (!_isConfigured || _client == null || !_isSignedIn) return [];

    try {
      final response = await _client!
          .from('companies')
          .select()
          .order('name', ascending: true);

      final list = (response as List)
          .map((item) => CompanyModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      // If user has zero companies in remote database, seed the defaults
      if (list.isEmpty) {
        await seedDefaultCompanies();
        return await fetchCompanies();
      }

      return list;
    } catch (e) {
      debugPrint('Error fetching companies from Supabase: $e');
      return [];
    }
  }

  Future<void> seedDefaultCompanies() async {
    if (!_isConfigured || _client == null || !_isSignedIn) return;

    try {
      final uid = currentUserId;
      final payload = AppConstants.defaultCompanies.map((name) {
        return {
          'user_id': uid,
          'name': name,
        };
      }).toList();

      await _client!.from('companies').upsert(
            payload,
            onConflict: 'user_id, name',
          );
      debugPrint('Default companies seeded successfully in Supabase.');
    } catch (e) {
      debugPrint('Error seeding default companies: $e');
    }
  }

  Future<CompanyModel?> createCompany(String name) async {
    if (!_isConfigured || _client == null || !_isSignedIn) return null;

    try {
      final uid = currentUserId;
      final res = await _client!.from('companies').insert({
        'name': name.trim(),
        'user_id': uid,
      }).select().single();

      return CompanyModel.fromJson(Map<String, dynamic>.from(res));
    } catch (e) {
      debugPrint('Error creating company in Supabase: $e');
      return null;
    }
  }

  Future<bool> updateCompany(String id, String newName) async {
    if (!_isConfigured || _client == null || !_isSignedIn) return false;

    try {
      await _client!
          .from('companies')
          .update({'name': newName.trim()})
          .eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error updating company in Supabase: $e');
      return false;
    }
  }

  Future<bool> deleteCompany(String id) async {
    if (!_isConfigured || _client == null || !_isSignedIn) return false;

    try {
      await _client!.from('companies').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error deleting company from Supabase: $e');
      return false;
    }
  }

  // ==========================================
  // Batteries Remote Operations
  // ==========================================
  Future<List<BatteryModel>> fetchBatteries() async {
    if (!_isConfigured || _client == null || !_isSignedIn) return [];

    try {
      final response = await _client!
          .from('batteries')
          .select()
          .order('expiry_date', ascending: true);

      return (response as List)
          .map((item) => BatteryModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      debugPrint('Error fetching batteries from Supabase: $e');
      return [];
    }
  }

  Future<bool> upsertBattery(BatteryModel battery) async {
    if (!_isConfigured || _client == null || !_isSignedIn) return false;

    try {
      final json = battery.toJson();
      if (battery.userId == null && currentUserId != null) {
        json['user_id'] = currentUserId;
      }
      await _client!.from('batteries').upsert(json);
      return true;
    } catch (e) {
      debugPrint('Error upserting battery in Supabase: $e');
      return false;
    }
  }

  Future<bool> deleteBattery(String id) async {
    if (!_isConfigured || _client == null || !_isSignedIn) return false;

    try {
      await _client!.from('batteries').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error deleting battery from Supabase: $e');
      return false;
    }
  }
}
