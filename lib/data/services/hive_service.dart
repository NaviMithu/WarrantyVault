import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../models/battery_model.dart';
import '../models/company_model.dart';

class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  late Box _batteriesBox;
  late Box _companiesBox;
  late Box _syncQueueBox;
  late Box _settingsBox;

  Future<void> init() async {
    await Hive.initFlutter();
    _batteriesBox = await Hive.openBox(AppConstants.batteriesBox);
    _companiesBox = await Hive.openBox(AppConstants.companiesBox);
    _syncQueueBox = await Hive.openBox(AppConstants.syncQueueBox);
    _settingsBox = await Hive.openBox(AppConstants.settingsBox);
    debugPrint('HiveService initialized successfully.');
  }

  // ==========================================
  // Batteries Local Cache
  // ==========================================
  List<BatteryModel> getAllBatteries() {
    final list = <BatteryModel>[];
    for (var i = 0; i < _batteriesBox.length; i++) {
      final item = _batteriesBox.getAt(i);
      if (item is Map) {
        try {
          list.add(BatteryModel.fromHiveMap(item));
        } catch (e) {
          debugPrint('Error parsing cached battery: $e');
        }
      }
    }
    // Sort default by expiry date ascending
    list.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return list;
  }

  BatteryModel? getBatteryById(String id) {
    final item = _batteriesBox.get(id);
    if (item is Map) {
      try {
        return BatteryModel.fromHiveMap(item);
      } catch (e) {
        debugPrint('Error parsing cached battery by id: $e');
      }
    }
    return null;
  }

  Future<void> saveBattery(BatteryModel battery) async {
    await _batteriesBox.put(battery.id, battery.toHiveMap());
  }

  Future<void> saveAllBatteries(List<BatteryModel> batteries) async {
    final map = <String, Map<String, dynamic>>{};
    for (final b in batteries) {
      map[b.id] = b.toHiveMap();
    }
    await _batteriesBox.putAll(map);
  }

  Future<void> deleteBattery(String id) async {
    await _batteriesBox.delete(id);
  }

  Future<void> clearBatteries() async {
    await _batteriesBox.clear();
  }

  // ==========================================
  // Companies Local Cache
  // ==========================================
  List<CompanyModel> getAllCompanies() {
    final list = <CompanyModel>[];
    for (var i = 0; i < _companiesBox.length; i++) {
      final item = _companiesBox.getAt(i);
      if (item is Map) {
        try {
          list.add(CompanyModel.fromHiveMap(item));
        } catch (e) {
          debugPrint('Error parsing cached company: $e');
        }
      }
    }
    return list;
  }

  Future<void> saveCompany(CompanyModel company) async {
    await _companiesBox.put(company.id, company.toHiveMap());
  }

  Future<void> saveAllCompanies(List<CompanyModel> companies) async {
    final map = <String, Map<String, dynamic>>{};
    for (final c in companies) {
      map[c.id] = c.toHiveMap();
    }
    await _companiesBox.putAll(map);
  }

  Future<void> deleteCompany(String id) async {
    await _companiesBox.delete(id);
  }

  // ==========================================
  // Offline Sync Queue
  // ==========================================
  List<Map<String, dynamic>> getSyncQueue() {
    final queue = <Map<String, dynamic>>[];
    for (var i = 0; i < _syncQueueBox.length; i++) {
      final item = _syncQueueBox.getAt(i);
      final key = _syncQueueBox.keyAt(i);
      if (item is Map) {
        final entry = Map<String, dynamic>.from(item);
        entry['_queueKey'] = key;
        queue.add(entry);
      }
    }
    return queue;
  }

  Future<void> enqueueSyncOperation({
    required String table,
    required String action, // 'insert', 'update', 'delete'
    required String id,
    Map<String, dynamic>? payload,
  }) async {
    await _syncQueueBox.add({
      'table': table,
      'action': action,
      'id': id,
      'payload': payload,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> removeSyncOperation(dynamic queueKey) async {
    await _syncQueueBox.delete(queueKey);
  }

  Future<void> clearSyncQueue() async {
    await _syncQueueBox.clear();
  }

  // ==========================================
  // Settings (Theme, etc.)
  // ==========================================
  String getThemeMode() {
    return _settingsBox.get('theme_mode', defaultValue: 'system') as String;
  }

  Future<void> setThemeMode(String mode) async {
    await _settingsBox.put('theme_mode', mode);
  }
}
