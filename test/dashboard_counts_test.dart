import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_vault/data/models/battery_model.dart';
import 'package:warranty_vault/features/dashboard/dashboard_stats_provider.dart';

void main() {
  group('Dashboard Status Counts Calculation', () {
    final today = DateTime(2025, 6, 1);

    test('Computes exact counts for mixed battery statuses', () {
      final batteries = [
        // 2 Active (> 30 days away)
        BatteryModel.create(
          id: '1',
          vehicleNumber: 'TN37AB1001',
          ownerName: 'Alice',
          companyName: 'Exide',
          warrantyMonths: 24,
          purchaseDate: DateTime(2025, 1, 1), // Expiry Jan 2027 -> Active
        ),
        BatteryModel.create(
          id: '2',
          vehicleNumber: 'TN37AB1002',
          ownerName: 'Bob',
          companyName: 'Amaron',
          warrantyMonths: 12,
          purchaseDate: DateTime(2025, 1, 1), // Expiry Jan 2026 -> Active
        ),

        // 2 Expiring soon (within 30 days or today)
        BatteryModel.create(
          id: '3',
          vehicleNumber: 'TN37AB1003',
          ownerName: 'Charlie',
          companyName: 'Surya',
          warrantyMonths: 6,
          purchaseDate: DateTime(2024, 12, 1), // Expiry 1 June 2025 -> Today -> Expiring
        ),
        BatteryModel.create(
          id: '4',
          vehicleNumber: 'TN37AB1004',
          ownerName: 'David',
          companyName: 'Power',
          warrantyMonths: 6,
          purchaseDate: DateTime(2024, 12, 15), // Expiry 15 June 2025 (14 days left) -> Expiring
        ),

        // 1 Expired (< today)
        BatteryModel.create(
          id: '5',
          vehicleNumber: 'TN37AB1005',
          ownerName: 'Eve',
          companyName: 'Star',
          warrantyMonths: 12,
          purchaseDate: DateTime(2023, 1, 1), // Expiry Jan 2024 -> Expired
        ),
      ];

      final stats = DashboardStats.fromBatteries(batteries, today);

      expect(stats.total, 5);
      expect(stats.active, 2);
      expect(stats.expiringSoon, 2);
      expect(stats.expired, 1);
      // Total must always equal Active + Expiring Soon + Expired
      expect(stats.total, stats.active + stats.expiringSoon + stats.expired);

      // Expiring soon list should have the 2 soonest batteries sorted
      expect(stats.expiringSoonList.length, 2);
      expect(stats.expiringSoonList.first.id, '3'); // June 1 comes before June 15
    });

    test('Empty battery list produces zero counts safely', () {
      final stats = DashboardStats.fromBatteries([], today);
      expect(stats.total, 0);
      expect(stats.active, 0);
      expect(stats.expiringSoon, 0);
      expect(stats.expired, 0);
      expect(stats.expiringSoonList.isEmpty, isTrue);
    });
  });
}
