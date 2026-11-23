import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/company_model.dart';
import '../../data/repositories/battery_repository.dart';
import '../../data/repositories/company_repository.dart';

class ManageCompaniesScreen extends ConsumerStatefulWidget {
  const ManageCompaniesScreen({super.key});

  @override
  ConsumerState<ManageCompaniesScreen> createState() => _ManageCompaniesScreenState();
}

class _ManageCompaniesScreenState extends ConsumerState<ManageCompaniesScreen> {
  Future<void> _showAddCompanyDialog() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Battery Company'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              textCapitalization: TextCapitalization.words,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'e.g. SF Sonic, Bosch, Exide...',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter company name';
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final repo = ref.read(companyRepositoryProvider);
                  await repo.addCompany(controller.text);
                  ref.invalidate(companiesListProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showRenameCompanyDialog(CompanyModel company) async {
    final controller = TextEditingController(text: company.name);
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Rename Company'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              textCapitalization: TextCapitalization.words,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Company name'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter company name';
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final repo = ref.read(companyRepositoryProvider);
                  await repo.renameCompany(company.id, controller.text);
                  ref.invalidate(companiesListProvider);
                  // Refresh battery list so updated company name appears everywhere
                  ref.read(batteryListStateProvider.notifier).loadBatteries();
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleDeleteCompany(CompanyModel company) async {
    if (company.batteryCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot delete "${company.name}" because ${company.batteryCount} battery entries are associated with it.',
          ),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Company'),
          content: Text('Delete company "${company.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final repo = ref.read(companyRepositoryProvider);
      await repo.deleteCompany(company.id);
      ref.invalidate(companiesListProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final companiesAsync = ref.watch(companiesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Companies',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCompanyDialog,
        backgroundColor: isDark ? AppColors.primaryDark : AppColors.primaryLight,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: companiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (companies) {
          if (companies.isEmpty) {
            return const Center(child: Text('No companies found. Tap + to add one.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: companies.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final comp = companies[index];

              return Card(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                child: ListTile(
                  title: Text(
                    comp.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${comp.batteryCount} ${comp.batteryCount == 1 ? "battery" : "batteries"}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        tooltip: 'Rename',
                        onPressed: () => _showRenameCompanyDialog(comp),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: comp.batteryCount > 0 ? Colors.grey : const Color(0xFFEF4444),
                        ),
                        tooltip: comp.batteryCount > 0 ? 'Cannot delete (in use)' : 'Delete',
                        onPressed: () => _handleDeleteCompany(comp),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
