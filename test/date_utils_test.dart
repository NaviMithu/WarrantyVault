import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_vault/core/utils/date_utils.dart';

void main() {
  group('Expiry Date Calculation & Clamping', () {
    test('Standard addition: 15 Jan 2024 + 12 months = 15 Jan 2025', () {
      final purchase = DateTime(2024, 1, 15);
      final expiry = AppDateUtils.calculateExpiryDate(purchase, 12);
      expect(expiry.year, 2025);
      expect(expiry.month, 1);
      expect(expiry.day, 15);
    });

    test('Standard addition: 10 May 2023 + 24 months = 10 May 2025', () {
      final purchase = DateTime(2023, 5, 10);
      final expiry = AppDateUtils.calculateExpiryDate(purchase, 24);
      expect(expiry.year, 2025);
      expect(expiry.month, 5);
      expect(expiry.day, 10);
    });

    test('Month-end clamping: 31 Aug 2024 + 6 months = 28 Feb 2025 (non-leap year)', () {
      final purchase = DateTime(2024, 8, 31);
      final expiry = AppDateUtils.calculateExpiryDate(purchase, 6);
      expect(expiry.year, 2025);
      expect(expiry.month, 2);
      expect(expiry.day, 28);
    });

    test('Leap year clamping: 31 Aug 2023 + 6 months = 29 Feb 2024 (leap year)', () {
      final purchase = DateTime(2023, 8, 31);
      final expiry = AppDateUtils.calculateExpiryDate(purchase, 6);
      expect(expiry.year, 2024);
      expect(expiry.month, 2);
      expect(expiry.day, 29);
    });

    test('Leap year purchase clamping: 29 Feb 2024 + 12 months = 28 Feb 2025', () {
      final purchase = DateTime(2024, 2, 29);
      final expiry = AppDateUtils.calculateExpiryDate(purchase, 12);
      expect(expiry.year, 2025);
      expect(expiry.month, 2);
      expect(expiry.day, 28);
    });

    test('Month-end clamping to 30-day month: 31 Mar 2024 + 1 month = 30 Apr 2024', () {
      final purchase = DateTime(2024, 3, 31);
      final expiry = AppDateUtils.calculateExpiryDate(purchase, 1);
      expect(expiry.year, 2024);
      expect(expiry.month, 4);
      expect(expiry.day, 30);
    });

    test('Month-end clamping: 31 Jan 2024 + 1 month = 29 Feb 2024', () {
      final purchase = DateTime(2024, 1, 31);
      final expiry = AppDateUtils.calculateExpiryDate(purchase, 1);
      expect(expiry.year, 2024);
      expect(expiry.month, 2);
      expect(expiry.day, 29);
    });
  });

  group('Days Remaining & Warranty Progress', () {
    test('Calculates positive days remaining for future expiry', () {
      final today = DateTime(2025, 1, 1);
      final expiry = DateTime(2025, 1, 11);
      expect(AppDateUtils.daysRemaining(expiry, today), 10);
    });

    test('Calculates 0 days remaining when expiring today', () {
      final today = DateTime(2025, 1, 1);
      final expiry = DateTime(2025, 1, 1);
      expect(AppDateUtils.daysRemaining(expiry, today), 0);
    });

    test('Calculates negative days remaining when expired', () {
      final today = DateTime(2025, 1, 5);
      final expiry = DateTime(2025, 1, 1);
      expect(AppDateUtils.daysRemaining(expiry, today), -4);
    });

    test('Calculates warranty progress used accurately', () {
      final purchase = DateTime(2024, 1, 1);
      final expiry = DateTime(2024, 1, 11); // 10 days
      final halfway = DateTime(2024, 1, 6); // 5 days used
      expect(AppDateUtils.warrantyUsedProgress(purchase, expiry, halfway), 0.5);
    });
  });
}
