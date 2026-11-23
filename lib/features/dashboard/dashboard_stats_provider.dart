import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/status_utils.dart';
import '../../data/models/battery_model.dart';
import '../../data/repositories/battery_repository.dart';

class DashboardStats {
  final int total;
  final int active; // Under warranty
  final int expiringSoon;
  final int expired;
  final List<BatteryModel> expiringSoonList;

  const DashboardStats({
    required this.total,
    required this.active,
    required this.expiringSoon,
    required this.expired,
    required this.expiringSoonList,
  });

  factory DashboardStats.fromBatteries(List<BatteryModel> batteries, [DateTime? today]) {
    int activeCount = 0;
    int expiringSoonCount = 0;
    int expiredCount = 0;
    final expiringList = <BatteryModel>[];

    for (final b in batteries) {
      final status = StatusUtils.classify(b.expiryDate, today);
      switch (status) {
        case BatteryStatus.active:
          activeCount++;
          break;
        case BatteryStatus.expiringSoon:
          expiringSoonCount++;
          expiringList.add(b);
          break;
        case BatteryStatus.expired:
          expiredCount++;
          break;
      }
    }

    // Sort expiring soon items by soonest expiry first
    expiringList.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

    return DashboardStats(
      total: batteries.length,
      active: activeCount,
      expiringSoon: expiringSoonCount,
      expired: expiredCount,
      expiringSoonList: expiringList,
    );
  }
}

/// One shared provider computing live status counts so Dashboard and All Batteries always agree.
final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final batteriesAsync = ref.watch(batteryListStateProvider);
  return batteriesAsync.maybeWhen(
    data: (batteries) => DashboardStats.fromBatteries(batteries),
    orElse: () => const DashboardStats(
      total: 0,
      active: 0,
      expiringSoon: 0,
      expired: 0,
      expiringSoonList: [],
    ),
  );
});
