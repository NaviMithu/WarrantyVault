import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_vault/core/utils/status_utils.dart';

void main() {
  group('Status Classification & Boundaries', () {
    final today = DateTime(2025, 6, 1);

    test('Expired: expiry date is yesterday (-1 day) -> expired', () {
      final expiry = DateTime(2025, 5, 31);
      expect(StatusUtils.classify(expiry, today), BatteryStatus.expired);
      expect(StatusUtils.getBadgeText(expiry, today), 'Expired yesterday');
    });

    test('Expired: expiry date was 5 days ago -> expired', () {
      final expiry = DateTime(2025, 5, 27);
      expect(StatusUtils.classify(expiry, today), BatteryStatus.expired);
      expect(StatusUtils.getBadgeText(expiry, today), 'Expired 5 days ago');
    });

    test('Boundary: expires today (0 days) -> expiringSoon', () {
      final expiry = DateTime(2025, 6, 1);
      expect(StatusUtils.classify(expiry, today), BatteryStatus.expiringSoon);
      expect(StatusUtils.getBadgeText(expiry, today), 'Expires today');
    });

    test('Boundary: expires in 1 day -> expiringSoon', () {
      final expiry = DateTime(2025, 6, 2);
      expect(StatusUtils.classify(expiry, today), BatteryStatus.expiringSoon);
      expect(StatusUtils.getBadgeText(expiry, today), 'Expires in 1 day');
    });

    test('Boundary: expires at exactly 30 days -> expiringSoon', () {
      final expiry = DateTime(2025, 7, 1); // 30 days after June 1
      expect(StatusUtils.classify(expiry, today), BatteryStatus.expiringSoon);
      expect(StatusUtils.getBadgeText(expiry, today), 'Expires in 30 days');
    });

    test('Boundary: expires at 31 days (more than 30 days) -> active', () {
      final expiry = DateTime(2025, 7, 2); // 31 days after June 1
      expect(StatusUtils.classify(expiry, today), BatteryStatus.active);
      expect(StatusUtils.getBadgeText(expiry, today), '31 days left');
    });

    test('Active: expires in 180 days -> active', () {
      final expiry = DateTime(2025, 11, 28);
      expect(StatusUtils.classify(expiry, today), BatteryStatus.active);
      expect(StatusUtils.getBadgeText(expiry, today), '180 days left');
    });
  });
}
