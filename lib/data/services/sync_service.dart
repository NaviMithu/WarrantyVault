import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/battery_model.dart';
import 'hive_service.dart';
import 'supabase_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final HiveService _hive = HiveService();
  final SupabaseService _supabase = SupabaseService();
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final ValueNotifier<bool> isOnlineNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> isSyncingNotifier = ValueNotifier<bool>(false);

  void init() {
    _checkInitialConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      isOnlineNotifier.value = isOnline;
      if (isOnline) {
        debugPrint('Device came online. Triggering background synchronization...');
        syncPendingOperations();
      }
    });
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    isOnlineNotifier.dispose();
    isSyncingNotifier.dispose();
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      isOnlineNotifier.value = isOnline;
      if (isOnline) {
        syncPendingOperations();
      }
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
    }
  }

  /// Processes all pending offline operations in the Hive sync queue.
  Future<void> syncPendingOperations() async {
    if (!isOnlineNotifier.value || !_supabase.isConfigured) return;
    if (isSyncingNotifier.value) return;

    isSyncingNotifier.value = true;
    try {
      // Ensure user is signed in
      if (!_supabase.isSignedIn) {
        await _supabase.silentSignIn();
      }
      if (!_supabase.isSignedIn) return;

      final queue = _hive.getSyncQueue();
      for (final item in queue) {
        final key = item['_queueKey'];
        final table = item['table'] as String;
        final action = item['action'] as String;
        final id = item['id'] as String;
        final payload = item['payload'] as Map<String, dynamic>?;

        bool success = false;
        if (table == 'batteries') {
          if (action == 'insert' || action == 'update') {
            if (payload != null) {
              final battery = BatteryModel.fromHiveMap(payload);
              success = await _supabase.upsertBattery(battery);
            }
          } else if (action == 'delete') {
            success = await _supabase.deleteBattery(id);
          }
        } else if (table == 'companies') {
          if (action == 'insert') {
            if (payload != null && payload['name'] != null) {
              final res = await _supabase.createCompany(payload['name'] as String);
              success = res != null;
            }
          } else if (action == 'update') {
            if (payload != null && payload['name'] != null) {
              success = await _supabase.updateCompany(id, payload['name'] as String);
            }
          } else if (action == 'delete') {
            success = await _supabase.deleteCompany(id);
          }
        }

        if (success) {
          await _hive.removeSyncOperation(key);
        }
      }
    } catch (e) {
      debugPrint('Error syncing pending operations: $e');
    } finally {
      isSyncingNotifier.value = false;
    }
  }

  /// Refreshes all batteries from Supabase and merges with local Hive cache using last-write-wins by updated_at.
  Future<List<BatteryModel>> pullAndMergeBatteries() async {
    if (!isOnlineNotifier.value || !_supabase.isConfigured) {
      return _hive.getAllBatteries();
    }

    try {
      if (!_supabase.isSignedIn) {
        await _supabase.silentSignIn();
      }

      // First sync pending writes
      await syncPendingOperations();

      final remoteBatteries = await _supabase.fetchBatteries();
      if (remoteBatteries.isEmpty) {
        // If remote is empty, perhaps user has local batteries not yet synced or fresh account
        final local = _hive.getAllBatteries();
        if (local.isNotEmpty && _supabase.isSignedIn) {
          // Push local to remote
          for (final b in local) {
            await _supabase.upsertBattery(b);
          }
        }
        return local;
      }

      final localBatteries = _hive.getAllBatteries();
      final localMap = {for (var b in localBatteries) b.id: b};

      final mergedList = <BatteryModel>[];
      for (final remote in remoteBatteries) {
        final local = localMap[remote.id];
        if (local == null) {
          mergedList.add(remote);
        } else {
          // Conflict resolution: Last write wins by updated_at
          if (local.updatedAt.isAfter(remote.updatedAt)) {
            mergedList.add(local);
            // Queue push to remote
            await _supabase.upsertBattery(local);
          } else {
            mergedList.add(remote);
          }
        }
      }

      // Save merged to local Hive cache
      await _hive.saveAllBatteries(mergedList);
      return mergedList;
    } catch (e) {
      debugPrint('Error pulling batteries: $e. Returning local cache.');
      return _hive.getAllBatteries();
    }
  }
}
