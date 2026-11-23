import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/date_utils.dart';
import '../../core/utils/normalization.dart';
import '../models/battery_model.dart';
import '../services/hive_service.dart';
import '../services/supabase_service.dart';
import '../services/sync_service.dart';

/// Single source of truth for battery list in Riverpod
final batteryListStateProvider = StateNotifierProvider<BatteryListNotifier, AsyncValue<List<BatteryModel>>>((ref) {
  final repo = ref.watch(batteryRepositoryProvider);
  return BatteryListNotifier(repo);
});

final batteryRepositoryProvider = Provider<BatteryRepository>((ref) {
  return BatteryRepository();
});

class BatteryListNotifier extends StateNotifier<AsyncValue<List<BatteryModel>>> {
  final BatteryRepository _repo;

  BatteryListNotifier(this._repo) : super(const AsyncValue.loading()) {
    loadBatteries();
  }

  Future<void> loadBatteries({bool forceRefresh = false}) async {
    try {
      if (forceRefresh) {
        state = const AsyncValue.loading();
      }
      final items = await _repo.getBatteries(forceRefresh: forceRefresh);
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addOrUpdateBattery(BatteryModel battery) async {
    await _repo.saveBattery(battery);
    await loadBatteries();
  }

  Future<BatteryModel?> deleteBattery(String id) async {
    final deleted = await _repo.deleteBattery(id);
    await loadBatteries();
    return deleted;
  }

  Future<void> restoreBattery(BatteryModel battery) async {
    await _repo.restoreBattery(battery);
    await loadBatteries();
  }
}

class BatteryRepository {
  final HiveService _hive = HiveService();
  final SupabaseService _supabase = SupabaseService();
  final SyncService _sync = SyncService();
  final Uuid _uuid = const Uuid();

  /// Reads from local Hive cache first, triggers remote pull in background if online.
  Future<List<BatteryModel>> getBatteries({bool forceRefresh = false}) async {
    if (forceRefresh) {
      return await _sync.pullAndMergeBatteries();
    }

    final local = _hive.getAllBatteries();
    if (local.isEmpty && _sync.isOnlineNotifier.value && _supabase.isConfigured) {
      return await _sync.pullAndMergeBatteries();
    }

    // Trigger background merge if online
    if (_sync.isOnlineNotifier.value && _supabase.isConfigured) {
      _sync.pullAndMergeBatteries().catchError((e) {
        debugPrint('Background merge error: $e');
        return local;
      });
    }

    return local;
  }

  Future<BatteryModel?> getBatteryById(String id) async {
    return _hive.getBatteryById(id);
  }

  /// Returns other battery entries for the same vehicle (battery replacements).
  List<BatteryModel> getPreviousBatteriesForVehicle({
    required String vehicleNumber,
    required String currentBatteryId,
  }) {
    final cleanVehicle = NormalizationUtils.normalizeVehicleNumber(vehicleNumber);
    final all = _hive.getAllBatteries();

    return all.where((b) =>
        b.id != currentBatteryId &&
        NormalizationUtils.normalizeVehicleNumber(b.vehicleNumber) == cleanVehicle
    ).toList()
      ..sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate)); // Newest first
  }

  /// Saves or updates a battery entry.
  Future<void> saveBattery(BatteryModel battery) async {
    // Save to Hive cache immediately
    await _hive.saveBattery(battery);

    // Sync or queue
    if (_sync.isOnlineNotifier.value && _supabase.isConfigured && _supabase.isSignedIn) {
      final success = await _supabase.upsertBattery(battery);
      if (!success) {
        await _hive.enqueueSyncOperation(
          table: 'batteries',
          action: 'insert',
          id: battery.id,
          payload: battery.toHiveMap(),
        );
      }
    } else {
      await _hive.enqueueSyncOperation(
        table: 'batteries',
        action: 'insert',
        id: battery.id,
        payload: battery.toHiveMap(),
      );
    }
  }

  /// Deletes a battery entry and returns the deleted object for Undo.
  Future<BatteryModel?> deleteBattery(String id) async {
    final existing = _hive.getBatteryById(id);
    if (existing == null) return null;

    await _hive.deleteBattery(id);

    if (_sync.isOnlineNotifier.value && _supabase.isConfigured && _supabase.isSignedIn) {
      final success = await _supabase.deleteBattery(id);
      if (!success) {
        await _hive.enqueueSyncOperation(
          table: 'batteries',
          action: 'delete',
          id: id,
        );
      }
    } else {
      await _hive.enqueueSyncOperation(
        table: 'batteries',
        action: 'delete',
        id: id,
      );
    }

    return existing;
  }

  /// Restores a deleted battery (for the 5-second Undo feature).
  Future<void> restoreBattery(BatteryModel battery) async {
    await saveBattery(battery);
  }

  // ==========================================
  // CSV Export & Import
  // ==========================================
  Future<File> generateCsvFile() async {
    final batteries = _hive.getAllBatteries();
    final headers = [
      'Vehicle Number',
      'Owner Name',
      'Company Name',
      'Warranty Months',
      'Purchase Date',
      'Expiry Date',
      'Owner Phone',
      'Notes',
    ];

    final rows = <List<dynamic>>[headers];
    for (final b in batteries) {
      rows.add([
        b.vehicleNumber,
        b.ownerName,
        b.companyName,
        b.warrantyMonths,
        AppDateUtils.formatIso(b.purchaseDate),
        AppDateUtils.formatIso(b.expiryDate),
        b.ownerPhone ?? '',
        b.notes ?? '',
      ]);
    }

    final csvString = const ListToCsvConverter().convert(rows);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/WarrantyVault_Export_${DateTime.now().millisecondsSinceEpoch}.csv');
    return await file.writeAsString(csvString);
  }

  Future<bool> exportCsvAndShare() async {
    try {
      final file = await generateCsvFile();
      final xFile = XFile(file.path, mimeType: 'text/csv');
      await Share.shareXFiles(
        [xFile],
        text: 'WarrantyVault Battery Export (${DateTime.now().toString().substring(0, 10)})',
      );
      return true;
    } catch (e) {
      debugPrint('Error exporting CSV: $e');
      return false;
    }
  }

  /// Imports CSV, skips exact duplicates, recalculates expiry date.
  Future<ImportResult> importCsv(String csvContent) async {
    try {
      final rows = const CsvToListConverter(shouldParseNumbers: false).convert(csvContent);
      if (rows.length <= 1) {
        return ImportResult(success: false, message: 'CSV file is empty or missing data rows.');
      }

      final existingBatteries = _hive.getAllBatteries();
      int importedCount = 0;
      int skippedDuplicates = 0;

      // Identify header column indexes
      final headerRow = rows.first.map((e) => e.toString().trim().toLowerCase()).toList();
      int colVehicle = headerRow.indexWhere((h) => h.contains('vehicle'));
      int colOwner = headerRow.indexWhere((h) => h.contains('owner') && !h.contains('phone'));
      int colCompany = headerRow.indexWhere((h) => h.contains('company'));
      int colWarranty = headerRow.indexWhere((h) => h.contains('warranty'));
      int colPurchase = headerRow.indexWhere((h) => h.contains('purchase') || h.contains('bought'));
      int colPhone = headerRow.indexWhere((h) => h.contains('phone'));
      int colNotes = headerRow.indexWhere((h) => h.contains('notes') || h.contains('note'));

      // Fallbacks if standard header match failed
      if (colVehicle == -1) colVehicle = 0;
      if (colOwner == -1) colOwner = 1;
      if (colCompany == -1) colCompany = 2;
      if (colWarranty == -1) colWarranty = 3;
      if (colPurchase == -1) colPurchase = 4;
      if (colPhone == -1) colPhone = 6;
      if (colNotes == -1) colNotes = 7;

      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty || row.every((c) => c.toString().trim().isEmpty)) continue;

        final vehicleStr = colVehicle < row.length ? row[colVehicle].toString() : '';
        final ownerStr = colOwner < row.length ? row[colOwner].toString() : '';
        final companyStr = colCompany < row.length ? row[colCompany].toString() : '';
        final warrantyStr = colWarranty < row.length ? row[colWarranty].toString() : '24';
        final purchaseStr = colPurchase < row.length ? row[colPurchase].toString() : '';
        final phoneStr = colPhone < row.length ? row[colPhone].toString() : null;
        final notesStr = colNotes < row.length ? row[colNotes].toString() : null;

        if (vehicleStr.trim().isEmpty || ownerStr.trim().isEmpty) continue;

        final cleanVehicle = NormalizationUtils.normalizeVehicleNumber(vehicleStr);
        final cleanCompany = NormalizationUtils.normalizeCompanyName(companyStr.isEmpty ? 'Exide' : companyStr);
        final warrantyMonths = int.tryParse(warrantyStr.trim()) ?? 24;
        final purchaseDate = AppDateUtils.parseDate(purchaseStr);

        // Check exact duplicate: vehicle, company, purchase_date
        final isDuplicate = existingBatteries.any((b) =>
            b.vehicleNumber == cleanVehicle &&
            b.companyName.toLowerCase() == cleanCompany.toLowerCase() &&
            b.purchaseDate.year == purchaseDate.year &&
            b.purchaseDate.month == purchaseDate.month &&
            b.purchaseDate.day == purchaseDate.day);

        if (isDuplicate) {
          skippedDuplicates++;
          continue;
        }

        // Create new battery with auto-recalculated expiry_date
        final newBattery = BatteryModel.create(
          id: _uuid.v4(),
          userId: _supabase.currentUserId,
          vehicleNumber: cleanVehicle,
          ownerName: ownerStr,
          companyName: cleanCompany,
          warrantyMonths: warrantyMonths,
          purchaseDate: purchaseDate,
          ownerPhone: phoneStr,
          notes: notesStr,
        );

        await saveBattery(newBattery);
        importedCount++;
      }

      return ImportResult(
        success: true,
        message: 'Imported $importedCount entries ($skippedDuplicates duplicates skipped).',
        importedCount: importedCount,
        skippedCount: skippedDuplicates,
      );
    } catch (e) {
      return ImportResult(success: false, message: 'Failed to parse CSV: $e');
    }
  }
}

class ImportResult {
  final bool success;
  final String message;
  final int importedCount;
  final int skippedCount;

  ImportResult({
    required this.success,
    required this.message,
    this.importedCount = 0,
    this.skippedCount = 0,
  });
}
