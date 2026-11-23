import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/battery_model.dart';
import '../../data/repositories/battery_repository.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/warranty_progress_bar.dart';

class BatteryDetailScreen extends ConsumerWidget {
  final String batteryId;

  const BatteryDetailScreen({
    super.key,
    required this.batteryId,
  });

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d\+]'), '');
    final uri = Uri(scheme: 'tel', path: cleanPhone);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot launch phone dialer.')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error dialing phone: $e')),
      );
    }
  }

  void _shareDetails(BatteryModel b) {
    final text = '''
Vehicle: ${b.vehicleNumber}
Owner: ${b.ownerName}
Company: ${b.companyName}
Warranty Period: ${b.warrantyMonths} Months
Bought Date: ${AppDateUtils.formatDisplay(b.purchaseDate)}
Expiry Date: ${AppDateUtils.formatDisplay(b.expiryDate)} (${b.statusBadgeText})
${b.ownerPhone != null ? 'Phone: ${b.ownerPhone}\n' : ''}${b.notes != null ? 'Notes: ${b.notes}\n' : ''}
Tracked with WarrantyVault
''';
    Share.share(text.trim());
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref, BatteryModel battery) async {
    final confirmed = await ConfirmDialog.showDeleteBattery(
      context: context,
      vehicleNumber: battery.vehicleNumber,
    );
    if (!confirmed || !context.mounted) return;

    final deleted = await ref.read(batteryListStateProvider.notifier).deleteBattery(battery.id);
    if (!context.mounted || deleted == null) return;

    context.pop(); // Return to previous screen

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final batteriesAsync = ref.watch(batteryListStateProvider);

    return batteriesAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (batteries) {
        final battery = batteries.where((b) => b.id == batteryId).firstOrNull;

        if (battery == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Battery Detail')),
            body: const Center(child: Text('Entry not found or was deleted.')),
          );
        }

        final previousBatteries = ref
            .read(batteryRepositoryProvider)
            .getPreviousBatteriesForVehicle(
              vehicleNumber: battery.vehicleNumber,
              currentBatteryId: battery.id,
            );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Battery Details'),
            actions: [
              IconButton(
                tooltip: 'Share',
                icon: const Icon(Icons.share_rounded),
                onPressed: () => _shareDetails(battery),
              ),
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_rounded),
                onPressed: () => context.push('/edit/${battery.id}'),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Vehicle Number & Status Badge Header
                Card(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              battery.vehicleNumber,
                              style: GoogleFonts.poppins(
                                fontSize: 24,
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
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Warranty Period',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                            Text(
                              '${battery.warrantyMonths} Months',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        WarrantyProgressBar(
                          progress: battery.progressUsed,
                          status: battery.status,
                          height: 6,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Bought: ${AppDateUtils.formatDisplay(battery.purchaseDate)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                            Text(
                              'Expires: ${AppDateUtils.formatDisplay(battery.expiryDate)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: battery.status.color,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Info Card
                Card(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        _buildInfoRow('Owner Name', battery.ownerName, isDark),
                        const Divider(height: 20),
                        _buildInfoRow('Battery Company', battery.companyName, isDark),
                        if (battery.ownerPhone != null && battery.ownerPhone!.isNotEmpty) ...[
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Owner Phone',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    battery.ownerPhone!,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.statusActive,
                                  visualDensity: VisualDensity.compact,
                                ),
                                icon: const Icon(Icons.call_rounded, size: 16),
                                label: const Text('Call'),
                                onPressed: () => _makePhoneCall(context, battery.ownerPhone!),
                              ),
                            ],
                          ),
                        ],
                        if (battery.notes != null && battery.notes!.isNotEmpty) ...[
                          const Divider(height: 20),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Notes',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  battery.notes!,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Action Buttons Row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text('Edit Entry'),
                        onPressed: () => context.push('/edit/${battery.id}'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.delete_rounded, size: 18),
                        label: const Text('Delete'),
                        onPressed: () => _handleDelete(context, ref, battery),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 4. Previous batteries for this vehicle (if any)
                if (previousBatteries.isNotEmpty) ...[
                  Text(
                    'Previous Batteries for this Vehicle',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: previousBatteries.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final prev = previousBatteries[index];
                      return Card(
                        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                        child: ListTile(
                          onTap: () => context.push('/battery/${prev.id}'),
                          title: Text(
                            prev.companyName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Bought: ${AppDateUtils.formatDisplay(prev.purchaseDate)}  •  Expired: ${AppDateUtils.formatDisplay(prev.expiryDate)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: StatusBadge(
                            status: prev.status,
                            text: prev.statusBadgeText,
                            compact: true,
                          ),
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
