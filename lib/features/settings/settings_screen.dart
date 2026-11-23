import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';
import '../../data/repositories/battery_repository.dart';
import '../../widgets/export_csv_button.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isImporting = false;

  Future<void> _handleImportCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      setState(() => _isImporting = true);

      final file = result.files.first;
      String csvContent = '';

      if (file.bytes != null) {
        csvContent = utf8.decode(file.bytes!);
      } else if (file.path != null) {
        csvContent = await File(file.path!).readAsString();
      }

      if (csvContent.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected CSV file is empty.')),
        );
        setState(() => _isImporting = false);
        return;
      }

      final repo = ref.read(batteryRepositoryProvider);
      final importResult = await repo.importCsv(csvContent);

      // Refresh list and dashboard counts
      await ref.read(batteryListStateProvider.notifier).loadBatteries();

      if (!mounted) return;
      setState(() => _isImporting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(importResult.message),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isImporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error importing CSV: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentThemeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Appearance Section
            _buildSectionHeader('Appearance', isDark),
            Card(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              child: Column(
                children: [
                  RadioListTile<ThemeMode>(
                    title: const Text('System Default'),
                    subtitle: const Text('Follow Android device theme'),
                    value: ThemeMode.system,
                    groupValue: currentThemeMode,
                    onChanged: (mode) {
                      if (mode != null) {
                        ref.read(themeModeProvider.notifier).setTheme(mode);
                      }
                    },
                  ),
                  const Divider(height: 1),
                  RadioListTile<ThemeMode>(
                    title: const Text('Light Mode'),
                    value: ThemeMode.light,
                    groupValue: currentThemeMode,
                    onChanged: (mode) {
                      if (mode != null) {
                        ref.read(themeModeProvider.notifier).setTheme(mode);
                      }
                    },
                  ),
                  const Divider(height: 1),
                  RadioListTile<ThemeMode>(
                    title: const Text('Dark Mode'),
                    value: ThemeMode.dark,
                    groupValue: currentThemeMode,
                    onChanged: (mode) {
                      if (mode != null) {
                        ref.read(themeModeProvider.notifier).setTheme(mode);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Data & Management Section
            _buildSectionHeader('Data Management', isDark),
            Card(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.primaryDark : AppColors.primaryLight).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.business_rounded,
                        color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                        size: 20,
                      ),
                    ),
                    title: const Text('Manage Companies', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Add, rename or delete battery brands'),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () => context.push('/companies'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.statusActive.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.upload_file_rounded,
                        color: AppColors.statusActive,
                        size: 20,
                      ),
                    ),
                    title: const Text('Import CSV', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Import records and recalculate warranty expiry'),
                    trailing: _isImporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: _isImporting ? null : _handleImportCsv,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. About Section
            _buildSectionHeader('About', isDark),
            Card(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        AppConstants.iconSquarePath,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.battery_charging_full_rounded,
                          size: 40,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppConstants.appName,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Version ${AppConstants.appVersion}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Personal Vehicle Battery Warranty Tracker',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4. Muted Export CSV at the very bottom
            const ExportCsvButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        ),
      ),
    );
  }
}
