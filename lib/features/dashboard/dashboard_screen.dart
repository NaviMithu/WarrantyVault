import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/status_utils.dart';
import '../../data/models/battery_model.dart';
import '../../data/repositories/battery_repository.dart';
import '../../widgets/export_csv_button.dart';
import '../../widgets/status_badge.dart';
import 'dashboard_stats_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final stats = ref.watch(dashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                AppConstants.iconSquarePath,
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.battery_charging_full_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Dashboard',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(batteryListStateProvider.notifier).loadBatteries(forceRefresh: true);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Stat Cards Grid (2x2)
              _buildStatCardsGrid(context, stats, isDark),
              const SizedBox(height: 16),

              // 2. Donut Chart Card
              _buildDonutChartCard(context, stats, isDark),
              const SizedBox(height: 16),

              // 3. Expiring Soon Card
              _buildExpiringSoonCard(context, stats, isDark),

              // 4. Muted Export CSV at the bottom
              const ExportCsvButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 1. Stat Cards Grid (2x2)
  // ==========================================
  Widget _buildStatCardsGrid(BuildContext context, DashboardStats stats, bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Total Batteries',
                count: stats.total,
                icon: Icons.battery_full_rounded,
                accentColor: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                onTap: () => context.go('/batteries?filter=all'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Under Warranty',
                count: stats.active,
                icon: Icons.verified_rounded,
                accentColor: AppColors.statusActive,
                onTap: () => context.go('/batteries?filter=active'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Expiring Soon',
                count: stats.expiringSoon,
                icon: Icons.warning_amber_rounded,
                accentColor: AppColors.statusExpiring,
                onTap: () => context.go('/batteries?filter=expiring'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Expired',
                count: stats.expired,
                icon: Icons.cancel_rounded,
                accentColor: AppColors.statusExpired,
                onTap: () => context.go('/batteries?filter=expired'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // 2. Donut Chart Card (fl_chart)
  // ==========================================
  Widget _buildDonutChartCard(BuildContext context, DashboardStats stats, bool isDark) {
    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Card(
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Warranty Status Share',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            if (stats.total == 0)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.battery_charging_full_rounded,
                        size: 48,
                        color: textSecondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No batteries yet. Tap + to add your first one.',
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  SizedBox(
                    height: 190,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 3,
                            centerSpaceRadius: 58,
                            sections: [
                              if (stats.active > 0)
                                PieChartSectionData(
                                  value: stats.active.toDouble(),
                                  color: AppColors.statusActive,
                                  radius: 24,
                                  showTitle: false,
                                ),
                              if (stats.expiringSoon > 0)
                                PieChartSectionData(
                                  value: stats.expiringSoon.toDouble(),
                                  color: AppColors.statusExpiring,
                                  radius: 24,
                                  showTitle: false,
                                ),
                              if (stats.expired > 0)
                                PieChartSectionData(
                                  value: stats.expired.toDouble(),
                                  color: AppColors.statusExpired,
                                  radius: 24,
                                  showTitle: false,
                                ),
                            ],
                          ),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${stats.total}',
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              'Total Batteries',
                              style: TextStyle(
                                fontSize: 11,
                                color: textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Legend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ChartLegendItem(
                        label: 'Active',
                        count: stats.active,
                        color: AppColors.statusActive,
                        isDark: isDark,
                      ),
                      _ChartLegendItem(
                        label: 'Expiring',
                        count: stats.expiringSoon,
                        color: AppColors.statusExpiring,
                        isDark: isDark,
                      ),
                      _ChartLegendItem(
                        label: 'Expired',
                        count: stats.expired,
                        color: AppColors.statusExpired,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 3. Expiring Soon Card
  // ==========================================
  Widget _buildExpiringSoonCard(BuildContext context, DashboardStats stats, bool isDark) {
    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final top5 = stats.expiringSoonList.take(5).toList();

    return Card(
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.statusExpiring,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Expiring Soon',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => context.go('/batteries?filter=expiring&sort=expiry_asc'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (top5.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Nothing expiring in the next 30 days',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: top5.length,
                separatorBuilder: (context, index) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final battery = top5[index];
                  return _ExpiringBatteryRow(battery: battery, isDark: isDark);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _StatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: InkWell(
        onTap: onTap,
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
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 16, color: accentColor),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '$count',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartLegendItem extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool isDark;

  const _ChartLegendItem({
    required this.label,
    required this.count,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
      ],
    );
  }
}

class _ExpiringBatteryRow extends StatelessWidget {
  final BatteryModel battery;
  final bool isDark;

  const _ExpiringBatteryRow({
    required this.battery,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return InkWell(
      onTap: () => context.push('/battery/${battery.id}'),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.statusExpiring.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.battery_alert_rounded,
                color: AppColors.statusExpiring,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        battery.vehicleNumber,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          battery.companyName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    battery.ownerName,
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            StatusBadge(
              status: BatteryStatus.expiringSoon,
              text: battery.statusBadgeText,
              compact: true,
            ),
          ],
        ),
      ),
    );
  }
}
