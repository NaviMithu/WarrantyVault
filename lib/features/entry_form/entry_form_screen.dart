import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/normalization.dart';
import '../../data/models/battery_model.dart';
import '../../data/repositories/battery_repository.dart';
import '../../data/repositories/company_repository.dart';
import '../../widgets/confirm_dialog.dart';

class EntryFormScreen extends ConsumerStatefulWidget {
  final String? batteryId; // If provided, edit mode

  const EntryFormScreen({
    super.key,
    this.batteryId,
  });

  @override
  ConsumerState<EntryFormScreen> createState() => _EntryFormScreenState();
}

class _EntryFormScreenState extends ConsumerState<EntryFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _vehicleController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _companyController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _otherMonthsController = TextEditingController();

  final FocusNode _companyFocusNode = FocusNode();
  final LayerLink _companyLayerLink = LayerLink();
  OverlayEntry? _companyOverlayEntry;

  int _selectedWarrantyMonths = AppConstants.defaultWarrantyMonths;
  bool _isOtherMonths = false;
  DateTime _boughtDate = DateTime.now();
  String? _selectedCompanyId;
  BatteryModel? _existingBattery;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _boughtDate = AppDateUtils.toDateOnly(DateTime.now());

    _companyFocusNode.addListener(() {
      if (_companyFocusNode.hasFocus) {
        _showCompanyOverlay();
      } else {
        _removeCompanyOverlay();
      }
    });

    _companyController.addListener(() {
      if (_companyFocusNode.hasFocus) {
        _showCompanyOverlay();
      }
    });

    if (widget.batteryId != null) {
      _loadExistingBattery();
    }
  }

  Future<void> _loadExistingBattery() async {
    setState(() => _isLoading = true);
    final repo = ref.read(batteryRepositoryProvider);
    final battery = await repo.getBatteryById(widget.batteryId!);
    if (battery != null && mounted) {
      _existingBattery = battery;
      _vehicleController.text = battery.vehicleNumber;
      _ownerNameController.text = battery.ownerName;
      _companyController.text = battery.companyName;
      _selectedCompanyId = battery.companyId;
      _phoneController.text = battery.ownerPhone ?? '';
      _notesController.text = battery.notes ?? '';
      _boughtDate = battery.purchaseDate;

      if (AppConstants.warrantyMonthChips.contains(battery.warrantyMonths)) {
        _selectedWarrantyMonths = battery.warrantyMonths;
        _isOtherMonths = false;
      } else {
        _selectedWarrantyMonths = battery.warrantyMonths;
        _isOtherMonths = true;
        _otherMonthsController.text = battery.warrantyMonths.toString();
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _removeCompanyOverlay();
    _vehicleController.dispose();
    _ownerNameController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _otherMonthsController.dispose();
    _companyFocusNode.dispose();
    super.dispose();
  }

  DateTime get _calculatedExpiryDate {
    return AppDateUtils.calculateExpiryDate(_boughtDate, _selectedWarrantyMonths);
  }

  // ==========================================
  // Company Autocomplete Overlay
  // ==========================================
  void _showCompanyOverlay() {
    _removeCompanyOverlay();

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final companyRepo = ref.read(companyRepositoryProvider);
    final query = _companyController.text;
    final suggestions = companyRepo.getSuggestions(query);

    final showAddNewOption = query.trim().isNotEmpty &&
        !suggestions.any((s) => s.toLowerCase() == query.trim().toLowerCase());

    _companyOverlayEntry = OverlayEntry(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Positioned(
          width: MediaQuery.of(context).size.width - 32,
          child: CompositedTransformFollower(
            link: _companyLayerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 56),
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(12),
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 240),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  children: [
                    ...suggestions.map((name) {
                      return ListTile(
                        dense: true,
                        title: Text(
                          name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        onTap: () {
                          _companyController.text = name;
                          _removeCompanyOverlay();
                          _companyFocusNode.unfocus();
                        },
                      );
                    }),
                    if (showAddNewOption) ...[
                      const Divider(height: 1),
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryLight, size: 20),
                        title: Text(
                          "+ Add '${query.trim()}' as new company",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryLight,
                          ),
                        ),
                        onTap: () async {
                          final newComp = await companyRepo.addCompany(query.trim());
                          _companyController.text = newComp.name;
                          _selectedCompanyId = newComp.id;
                          _removeCompanyOverlay();
                          _companyFocusNode.unfocus();
                          ref.invalidate(companiesListProvider);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_companyOverlayEntry!);
  }

  void _removeCompanyOverlay() {
    _companyOverlayEntry?.remove();
    _companyOverlayEntry = null;
  }

  // ==========================================
  // Date Picker
  // ==========================================
  Future<void> _selectBoughtDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _boughtDate,
      firstDate: DateTime(2010),
      lastDate: DateTime.now(), // Bought date cannot be in the future
    );
    if (picked != null) {
      setState(() {
        _boughtDate = AppDateUtils.toDateOnly(picked);
      });
    }
  }

  // ==========================================
  // Save Entry
  // ==========================================
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final vehicle = NormalizationUtils.normalizeVehicleNumber(_vehicleController.text);
    final owner = _ownerNameController.text.trim();
    final companyName = NormalizationUtils.normalizeCompanyName(_companyController.text);

    if (companyName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter or select a battery company.')),
      );
      return;
    }

    // Auto-save company if not already existing
    final companyRepo = ref.read(companyRepositoryProvider);
    final savedCompany = await companyRepo.addCompany(companyName);

    final phone = _phoneController.text.trim();
    final notes = _notesController.text.trim();

    final battery = BatteryModel.create(
      id: _existingBattery?.id ?? const Uuid().v4(),
      userId: _existingBattery?.userId,
      vehicleNumber: vehicle,
      ownerName: owner,
      companyId: _selectedCompanyId ?? savedCompany.id,
      companyName: savedCompany.name,
      warrantyMonths: _selectedWarrantyMonths,
      purchaseDate: _boughtDate,
      ownerPhone: phone.isEmpty ? null : phone,
      notes: notes.isEmpty ? null : notes,
      createdAt: _existingBattery?.createdAt,
      updatedAt: DateTime.now(),
    );

    await ref.read(batteryListStateProvider.notifier).addOrUpdateBattery(battery);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Saved'),
        duration: Duration(seconds: 2),
      ),
    );

    context.pop();
  }

  // ==========================================
  // Delete Entry (In Edit Mode)
  // ==========================================
  Future<void> _handleDelete() async {
    if (_existingBattery == null) return;

    final confirmed = await ConfirmDialog.showDeleteBattery(
      context: context,
      vehicleNumber: _existingBattery!.vehicleNumber,
    );
    if (!confirmed || !mounted) return;

    final deleted = await ref
        .read(batteryListStateProvider.notifier)
        .deleteBattery(_existingBattery!.id);

    if (!mounted || deleted == null) return;

    context.pop(); // Close form screen

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted entry for ${_existingBattery!.vehicleNumber}'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEdit = widget.batteryId != null;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Battery' : 'Add Battery',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () {
          _removeCompanyOverlay();
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Vehicle Number Field
                _buildFieldLabel('Vehicle Number *', isDark),
                TextFormField(
                  controller: _vehicleController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    hintText: 'e.g. TN37AB1234',
                    prefixIcon: Icon(Icons.directions_car_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter vehicle registration number';
                    }
                    if (NormalizationUtils.normalizeVehicleNumber(value).length < 4) {
                      return 'Please enter a valid vehicle number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 2. Owner Name Field
                _buildFieldLabel('Owner Name *', isDark),
                TextFormField(
                  controller: _ownerNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Rajesh Kumar',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter owner name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 3. Battery Company Autocomplete Field
                _buildFieldLabel('Battery Company *', isDark),
                CompositedTransformTarget(
                  link: _companyLayerLink,
                  child: TextFormField(
                    controller: _companyController,
                    focusNode: _companyFocusNode,
                    decoration: InputDecoration(
                      hintText: 'e.g. Exide, Amaron, Surya...',
                      prefixIcon: const Icon(Icons.business_rounded),
                      suffixIcon: _companyController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _companyController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter battery manufacturer';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // 4. Warranty Period Field (Choice Chips + Other)
                _buildFieldLabel('Warranty Period (Months) *', isDark),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ...AppConstants.warrantyMonthChips.map((months) {
                      final isSelected = !_isOtherMonths && _selectedWarrantyMonths == months;
                      return ChoiceChip(
                        label: Text('$months mos'),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedWarrantyMonths = months;
                              _isOtherMonths = false;
                            });
                          }
                        },
                      );
                    }),
                    ChoiceChip(
                      label: const Text('Other'),
                      selected: _isOtherMonths,
                      onSelected: (selected) {
                        setState(() {
                          _isOtherMonths = true;
                          final custom = int.tryParse(_otherMonthsController.text);
                          if (custom != null && custom >= 1 && custom <= 120) {
                            _selectedWarrantyMonths = custom;
                          } else {
                            _selectedWarrantyMonths = 6;
                            _otherMonthsController.text = '6';
                          }
                        });
                      },
                    ),
                  ],
                ),
                if (_isOtherMonths) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _otherMonthsController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      hintText: 'Enter whole months (1 - 120)',
                      prefixIcon: Icon(Icons.numbers_rounded),
                      suffixText: 'months',
                    ),
                    onChanged: (val) {
                      final parsed = int.tryParse(val);
                      if (parsed != null && parsed >= 1 && parsed <= 120) {
                        setState(() => _selectedWarrantyMonths = parsed);
                      }
                    },
                    validator: (val) {
                      if (!_isOtherMonths) return null;
                      final parsed = int.tryParse(val ?? '');
                      if (parsed == null || parsed < 1 || parsed > 120) {
                        return 'Please enter between 1 and 120 months';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 20),

                // 5. Bought Date Field
                _buildFieldLabel('Battery Bought Date *', isDark),
                InkWell(
                  onTap: _selectBoughtDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              AppDateUtils.formatDisplay(_boughtDate),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                          ],
                        ),
                        const Icon(Icons.arrow_drop_down_rounded),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 6. Live Expiry Preview Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0C243B) : const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF0369A1) : const Color(0xFFBAE6FD),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_user_rounded,
                        color: AppColors.primaryLight,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Warranty expires on: ${AppDateUtils.formatDisplay(_calculatedExpiryDate)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0369A1),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '($_selectedWarrantyMonths months from purchase)',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : const Color(0xFF0284C7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 7. Owner Phone Field (Optional)
                _buildFieldLabel('Owner Phone (Optional)', isDark),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 9876543210',
                    prefixIcon: Icon(Icons.phone_rounded),
                  ),
                ),
                const SizedBox(height: 16),

                // 8. Notes Field (Optional)
                _buildFieldLabel('Notes (Optional)', isDark),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Battery model DIN55, purchased at discount, replacement for old Amaron',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 28),

                // 9. Save Button
                ElevatedButton(
                  onPressed: _handleSave,
                  child: Text(isEdit ? 'Update Battery' : 'Save Battery'),
                ),

                // 10. Delete Button (in Edit Mode)
                if (isEdit) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: _handleDelete,
                      icon: const Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444)),
                      label: const Text(
                        'Delete this entry',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
    );
  }
}
