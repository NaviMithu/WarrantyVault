import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/fuzzy_match.dart';
import '../../core/utils/normalization.dart';
import '../models/company_model.dart';
import '../services/hive_service.dart';
import '../services/supabase_service.dart';
import '../services/sync_service.dart';

final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  return CompanyRepository();
});

final companiesListProvider = FutureProvider<List<CompanyModel>>((ref) async {
  final repo = ref.watch(companyRepositoryProvider);
  return repo.loadCompanies();
});

class CompanyRepository {
  final HiveService _hive = HiveService();
  final SupabaseService _supabase = SupabaseService();
  final SyncService _sync = SyncService();
  final Uuid _uuid = const Uuid();

  /// Loads companies from local cache first, seeds defaults if empty, and syncs from Supabase if online.
  Future<List<CompanyModel>> loadCompanies() async {
    var companies = _hive.getAllCompanies();

    if (companies.isEmpty) {
      // Seed default companies locally
      final now = DateTime.now();
      companies = AppConstants.defaultCompanies.map((name) {
        return CompanyModel(
          id: _uuid.v4(),
          name: name,
          createdAt: now,
        );
      }).toList();
      await _hive.saveAllCompanies(companies);
    }

    // Refresh from Supabase in background if online
    if (_sync.isOnlineNotifier.value && _supabase.isConfigured) {
      _fetchAndMergeRemote();
    }

    return _sortCompaniesWithBatteryCount(companies);
  }

  Future<void> _fetchAndMergeRemote() async {
    try {
      final remote = await _supabase.fetchCompanies();
      if (remote.isNotEmpty) {
        await _hive.saveAllCompanies(remote);
      }
    } catch (_) {}
  }

  /// Calculates battery count per company and sorts alphabetically
  List<CompanyModel> _sortCompaniesWithBatteryCount(List<CompanyModel> companies) {
    final batteries = _hive.getAllBatteries();
    final counts = <String, int>{};
    for (final b in batteries) {
      final key = b.companyName.toLowerCase();
      counts[key] = (counts[key] ?? 0) + 1;
    }

    final enriched = companies.map((c) {
      final count = counts[c.name.toLowerCase()] ?? 0;
      return c.copyWith(batteryCount: count);
    }).toList();

    enriched.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return enriched;
  }

  /// Returns company names ordered by usage frequency (for empty input autocomplete).
  List<String> getCompaniesByUsage() {
    final batteries = _hive.getAllBatteries();
    final frequency = <String, int>{};
    for (final b in batteries) {
      final key = b.companyName;
      frequency[key] = (frequency[key] ?? 0) + 1;
    }

    final all = _hive.getAllCompanies().map((c) => c.name).toSet();
    for (final c in AppConstants.defaultCompanies) {
      all.add(c);
    }

    final list = all.toList();
    list.sort((a, b) {
      final fa = frequency[a] ?? 0;
      final fb = frequency[b] ?? 0;
      if (fb != fa) return fb.compareTo(fa);
      return a.toLowerCase().compareTo(b.toLowerCase());
    });
    return list;
  }

  /// Ranks company suggestions using exact, prefix, contains, and fuzzy (Levenshtein <= 2).
  List<String> getSuggestions(String query) {
    final all = getCompaniesByUsage();
    return FuzzyMatch.rankSuggestions(query: query, allCompanies: all);
  }

  /// Adds a new company (avoids case-insensitive duplicates).
  Future<CompanyModel> addCompany(String name) async {
    final cleanName = NormalizationUtils.normalizeCompanyName(name);
    final all = _hive.getAllCompanies();

    // Check existing
    final existing = all.where((c) => c.name.toLowerCase() == cleanName.toLowerCase());
    if (existing.isNotEmpty) {
      return existing.first;
    }

    final company = CompanyModel(
      id: _uuid.v4(),
      name: cleanName,
      userId: _supabase.currentUserId,
      createdAt: DateTime.now(),
    );

    // Save to Hive
    await _hive.saveCompany(company);

    // Sync or Queue
    if (_sync.isOnlineNotifier.value && _supabase.isConfigured && _supabase.isSignedIn) {
      final remote = await _supabase.createCompany(cleanName);
      if (remote != null) {
        await _hive.saveCompany(remote);
        return remote;
      }
    } else {
      await _hive.enqueueSyncOperation(
        table: 'companies',
        action: 'insert',
        id: company.id,
        payload: {'name': cleanName},
      );
    }

    return company;
  }

  /// Renames an existing company and cascades name change to all corresponding batteries.
  Future<bool> renameCompany(String id, String newName) async {
    final cleanName = NormalizationUtils.normalizeCompanyName(newName);
    final all = _hive.getAllCompanies();
    final index = all.indexWhere((c) => c.id == id);
    if (index == -1) return false;

    final oldName = all[index].name;
    final updated = all[index].copyWith(name: cleanName);
    await _hive.saveCompany(updated);

    // Cascade update to batteries in Hive
    final batteries = _hive.getAllBatteries();
    for (final b in batteries) {
      if (b.companyName.toLowerCase() == oldName.toLowerCase() || b.companyId == id) {
        final updatedBattery = b.copyWith(
          companyName: cleanName,
          companyId: id,
          updatedAt: DateTime.now(),
        );
        await _hive.saveBattery(updatedBattery);
        if (!_sync.isOnlineNotifier.value || !_supabase.isConfigured) {
          await _hive.enqueueSyncOperation(
            table: 'batteries',
            action: 'update',
            id: updatedBattery.id,
            payload: updatedBattery.toHiveMap(),
          );
        } else {
          await _supabase.upsertBattery(updatedBattery);
        }
      }
    }

    // Sync company update
    if (_sync.isOnlineNotifier.value && _supabase.isConfigured && _supabase.isSignedIn) {
      await _supabase.updateCompany(id, cleanName);
    } else {
      await _hive.enqueueSyncOperation(
        table: 'companies',
        action: 'update',
        id: id,
        payload: {'name': cleanName},
      );
    }

    return true;
  }

  /// Deletes a company only if unused (0 batteries).
  Future<bool> deleteCompany(String id) async {
    final batteries = _hive.getAllBatteries();
    final all = _hive.getAllCompanies();
    final comp = all.firstWhere((c) => c.id == id, orElse: () => CompanyModel(id: '', name: '', createdAt: DateTime.now()));
    if (comp.id.isEmpty) return false;

    final isUsed = batteries.any((b) =>
        b.companyId == id || b.companyName.toLowerCase() == comp.name.toLowerCase());
    if (isUsed) {
      return false; // Cannot delete used company
    }

    await _hive.deleteCompany(id);

    if (_sync.isOnlineNotifier.value && _supabase.isConfigured && _supabase.isSignedIn) {
      await _supabase.deleteCompany(id);
    } else {
      await _hive.enqueueSyncOperation(
        table: 'companies',
        action: 'delete',
        id: id,
      );
    }
    return true;
  }
}
