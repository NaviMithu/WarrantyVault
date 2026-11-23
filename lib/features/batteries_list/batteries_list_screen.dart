import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/normalization.dart';
import '../../core/utils/status_utils.dart';
import '../../data/models/battery_model.dart';
import '../../data/repositories/battery_repository.dart';
import '../../data/repositories/company_repository.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/export_csv_button.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/warranty_progress_bar.dart';

enum BatterySortOption {
  expirySoonest('Expiry: soonest first'),
  expiryLatest('Expiry: latest first'),
  recentlyAdded('Recently added'),
  ownerAtoZ('Owner name A to Z'),
  companyAtoZ('Company A to Z'),
  vehicleNumber('Vehicle number');

  final String label;
  const BatterySortOption(this.label);
}

class BatteriesListScreen extends ConsumerStatefulWidget {
  final String? initialFilter; // 'all', 'active', 'expiring', 'expired'
  final String? initialSort;

  const BatteriesListScreen({
    super.key,
    this.initialFilter,
    this.initialSort,
  });

  @override
  ConsumerState<BatteriesListScreen> createState() => _BatteriesListScreenState();
}

class _BatteriesListScreenState extends ConsumerState<BatteriesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _searchQuery = '';

  String _statusFilter = 'all'; // 'all', 'active', 'expiring', 'expired'
  final Set<String> _selectedCompanies = {};
  DateTimeRange? _selectedDateRange;
  BatterySortOption _sortOption = BatterySortOption.expirySoonest;

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter != null) {
      _statusFilter = widget.initialFilter!;
    }
    if (widget.initialSort == 'expiry_asc') {
      _sortOption = BatterySortOption.expirySoonest;
    }
  }

  @override
  void didUpdateWidget(covariant BatteriesListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFilter != null && widget.initialFilter != oldWidget.initialFilter) {
      setState(() {
        _statusFilter = widget.initialFilter!;
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      setState(() {
        _searchQuery = value.trim();
      });
    });
  }

  void _clearFilters() {
    setState(() {
      _statusFilter = 'all';
      _selectedCompanies.clear();
      _selectedDateRange = null;
      _searchController.clear();
      _searchQuery = '';
    });
  }

  bool get _hasActiveFilters {
    return _statusFilter != 'all' ||
        _selectedCompanies.isNotEmpty ||
        _selectedDateRange != null ||
        _searchQuery.isNotEmpty;
  }

  List<BatteryModel> _filterAndSort(List<BatteryModel> allBatteries) {
    final query = _searchQuery.toLowerCase();
    final normalizedQueryVehicle = NormalizationUtils.normalizeVehicleNumber(_searchQuery);

    final filtered = allBatteries.where((b) {
      // 1. Search Query
      if (query.isNotEmpty) {
        final matchesOwner = b.ownerName.toLowerCase().contains(query);
        final matchesCompany = b.companyName.toLowerCase().contains(query);
        final matchesVehicle = NormalizationUtils.normalizeVehicleNumber(b.vehicleNumber)
            .contains(normalizedQueryVehicle);

        if (!matchesOwner && !matchesCompany && !matchesVehicle) {
          return false;
        }
      }

      // 2. Status Filter
      if (_statusFilter == 'active' && b.status != BatteryStatus.active) return false;
      if (_statusFilter == 'expiring' && b.status != BatteryStatus.expiringSoon) return false;
      if (_statusFilter == 'expired' && b.status != BatteryStatus.expired) return false;

      // 3. Company Filter
      if (_selectedCompanies.isNotEmpty) {
        if (!_selectedCompanies.contains(b.companyName.toLowerCase())) {
          return false;
        }
      }

      // 4. Expiry Date Range Filter
      if (_selectedDateRange != null) {
        final exp = b.expiryDate;
        final start = AppDateUtils.toDateOnly(_selectedDateRange!.start);
        final end = AppDateUtils.toDateOnly(_selectedDateRange!.end);
        if (exp.isBefore(start) || exp.isAfter(end)) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sorting
    switch (_sortOption) {
      case BatterySortOption.expirySoonest:
        filtered.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
        break;
      case BatterySortOption.expiryLatest:
        filtered.sort((a, b) => b.expiryDate.compareTo(a.expiryDate));
        break;
      case BatterySortOption.recentlyAdded:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case BatterySortOption.ownerAtoZ:
        filtered.sort((a, b) => a.ownerName.toLowerCase().compareTo(b.ownerName.toLowerCase()));
        break;
      case BatterySortOption.companyAtoZ:
        filtered.sort((a, b) => a.companyName.toLowerCase().compareTo(b.companyName.toLowerCase()));
        break;
      case BatterySortOption.vehicleNumber:
        filtered.sort((a, b) => a.vehicleNumber.compareTo(b.vehicleNumber));
        break;
    }

    return filtered;
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final batteriesAsync = ref.watch(batteryListStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'All Batteries',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Sort',
            icon: const Icon(Icons.sort_rounded),
            onPressed: () => _openSortBottomSheet(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 1. Pinned Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search vehicle, owner, or company...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),

          // 2. Horizontally Scrollable Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildFilterChip('All', 'all', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Expiring soon', 'expiring', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Active', 'active', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Expired', 'expired', isDark),
                const SizedBox(width: 8),

                // Company multi-select chip
                FilterChip(
                  label: Text(
                    _selectedCompanies.isEmpty
                        ? 'Company'
                        : 'Company (${_selectedCompanies.length})',
                  ),
                  selected: _selectedCompanies.isNotEmpty,
                  onSelected: (_) => _openCompanyFilterBottomSheet(context),
                ),
                const SizedBox(width: 8),

                // Expiry Date Range chip
                FilterChip(
                  label: Text(
                    _selectedDateRange == null
                        ? 'Date Range'
                        : '${AppDateUtils.formatDisplay(_selectedDateRange!.start)} - ${AppDateUtils.formatDisplay(_selectedDateRange!.end)}',
                  ),
                  selected: _selectedDateRange != null,
                  onSelected: (_) => _pickDateRange(context),
                ),

                if (_hasActiveFilters) ...[
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: const Icon(Icons.close_rounded, size: 14),
                    label: const Text('Clear filters'),
                    onPressed: _clearFilters,
                  ),
                ],
              ],
            ),
          ),

          // 3. Result Count Bar
          batteriesAsync.maybeWhen(
            data: (all) {
              final displayed = _filterAndSort(all);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${displayed.length} ${displayed.length == 1 ? "battery" : "batteries"}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    Text(
                      _sortOption.label,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),

          // 4. Batteries List
          Expanded(
            child: batteriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text('Error loading batteries: $err'),
              ),
              data: (allBatteries) {
                final displayed = _filterAndSort(allBatteries);

                if (displayed.isEmpty) {
                  return _buildEmptyState(context, isDark, allBatteries.isEmpty);
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(batteryListStateProvider.notifier).loadBatteries(forceRefresh: true);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: displayed.length + 1, // +1 for ExportCsvButton
                    itemBuilder: (context, index) {
                      if (index == displayed.length) {
                        return const ExportCsvButton();
                      }

                      final battery = displayed[index];
                      return _buildBatteryCard(context, battery, isDark);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isDark) {
    final isSelected = _statusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _statusFilter = value);
        }
      },
    );
  }

  Widget _buildBatteryCard(BuildContext context, BatteryModel battery, bool isDark) {
    return Dismissible(
      key: Key(battery.id),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: const Color(0xFF0284C7),
        child: const Row(
          children: [
            Icon(Icons.edit_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Edit',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: const Color(0xFFEF4444),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Delete',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete_rounded, color: Colors.white),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe right to edit
          context.push('/edit/${battery.id}');
          return false;
        } else {
          // Swipe left to delete with confirmation dialog
          return await ConfirmDialog.showDeleteBattery(
            context: context,
            vehicleNumber: battery.vehicleNumber,
          );
        }
      },
      onDismissed: (direction) async {
        if (direction == DismissDirection.endToStart) {
          final messenger = ScaffoldMessenger.of(context);
          final deleted = await ref.read(batteryListStateProvider.notifier).deleteBattery(battery.id);
          if (deleted == null) return;

          messenger.clearSnackBars();
          messenger.showSnackBar(
            SnackBar(
              content: Text('Deleted entry for ${battery.vehicleNumber}'),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'UNDO',
                textColor: const Color(0xFF38BDF8),
                onPressed: () {
                  ref.read(batteryListStateProvider.notifier).restoreBattery(deleted);
                },
              ),
            ),
          );
        }
      },
      child: Card(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        child: InkWell(
          onTap: () => context.push('/battery/${battery.id}'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      battery.vehicleNumber,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    StatusBadge(
                      status: battery.status,
                      text: battery.statusBadgeText,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      battery.ownerName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        battery.companyName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Expires: ${AppDateUtils.formatDisplay(battery.expiryDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    Text(
                      '${battery.warrantyMonths} months warranty',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Thin progress bar
                WarrantyProgressBar(
                  progress: battery.progressUsed,
                  status: battery.status,
                  height: 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark, bool isCompletelyEmpty) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCompletelyEmpty ? Icons.battery_charging_full_rounded : Icons.search_off_rounded,
              size: 56,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              isCompletelyEmpty
                  ? 'No batteries yet, tap + to add one'
                  : 'No results for your search or filters',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            if (!isCompletelyEmpty) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Reset filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================
  // Sort Bottom Sheet
  // ==========================================
  void _openSortBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Sort Entries By',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(),
                ...BatterySortOption.values.map((opt) {
                  return RadioListTile<BatterySortOption>(
                    value: opt,
                    groupValue: _sortOption,
                    title: Text(opt.label),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _sortOption = val);
                        Navigator.pop(ctx);
                      }
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // Company Multi-Select Filter Bottom Sheet
  // ==========================================
  void _openCompanyFilterBottomSheet(BuildContext context) {
    final companiesAsync = ref.read(companiesListProvider);
    final allCompanyNames = companiesAsync.maybeWhen(
      data: (list) => list.map((c) => c.name).toList(),
      orElse: () => ref.read(companyRepositoryProvider).getCompaniesByUsage(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Filter by Company',
                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () {
                              setSheetState(() => _selectedCompanies.clear());
                              setState(() {});
                            },
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: allCompanyNames.length,
                        itemBuilder: (context, index) {
                          final name = allCompanyNames[index];
                          final lower = name.toLowerCase();
                          final isChecked = _selectedCompanies.contains(lower);

                          return CheckboxListTile(
                            title: Text(name),
                            value: isChecked,
                            onChanged: (bool? checked) {
                              setSheetState(() {
                                if (checked == true) {
                                  _selectedCompanies.add(lower);
                                } else {
                                  _selectedCompanies.remove(lower);
                                }
                              });
                              setState(() {});
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // Expiry Date Range Picker
  // ==========================================
  Future<void> _pickDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2045),
      initialDateRange: _selectedDateRange ??
          DateTimeRange(
            start: DateTime.now(),
            end: DateTime.now().add(const Duration(days: 365)),
          ),
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }
}
