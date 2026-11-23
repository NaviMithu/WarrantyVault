import 'package:intl/intl.dart';

/// Pure date utilities for warranty calculations and display.
class AppDateUtils {
  static final DateFormat displayFormat = DateFormat('dd MMM yyyy');
  static final DateFormat isoFormat = DateFormat('yyyy-MM-dd');

  /// Normalizes a [DateTime] to date-only at midnight (stripping hours, minutes, seconds).
  static DateTime toDateOnly(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  /// Calculates the warranty expiry date by adding [months] to [purchaseDate].
  ///
  /// Clamps the day to the last day of the target month if the target month
  /// has fewer days than the purchase date's day (e.g., 31 Aug + 6 months -> 28/29 Feb).
  static DateTime calculateExpiryDate(DateTime purchaseDate, int months) {
    final cleanPurchaseDate = toDateOnly(purchaseDate);
    final totalMonths = (cleanPurchaseDate.year * 12) + (cleanPurchaseDate.month - 1) + months;
    final targetYear = totalMonths ~/ 12;
    final targetMonth = (totalMonths % 12) + 1;

    // Day 0 of the following month gives the last day of targetMonth
    final lastDayOfTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;
    final targetDay = cleanPurchaseDate.day > lastDayOfTargetMonth
        ? lastDayOfTargetMonth
        : cleanPurchaseDate.day;

    return DateTime(targetYear, targetMonth, targetDay);
  }

  /// Calculates the number of calendar days remaining until [expiryDate].
  ///
  /// If [today] is omitted, the current date (date-only) is used.
  /// Returns a positive number if future, 0 if today, negative if expired.
  static int daysRemaining(DateTime expiryDate, [DateTime? today]) {
    final current = toDateOnly(today ?? DateTime.now());
    final target = toDateOnly(expiryDate);
    return target.difference(current).inDays;
  }

  /// Calculates the proportion of warranty used, clamped between 0.0 and 1.0.
  static double warrantyUsedProgress(
    DateTime purchaseDate,
    DateTime expiryDate, [
    DateTime? today,
  ]) {
    final start = toDateOnly(purchaseDate);
    final end = toDateOnly(expiryDate);
    final current = toDateOnly(today ?? DateTime.now());

    final totalDays = end.difference(start).inDays;
    if (totalDays <= 0) return 1.0;

    final usedDays = current.difference(start).inDays;
    if (usedDays <= 0) return 0.0;
    if (usedDays >= totalDays) return 1.0;

    return usedDays / totalDays;
  }

  /// Formats date for UI display: "12 Mar 2027".
  static String formatDisplay(DateTime dt) {
    return displayFormat.format(dt);
  }

  /// Formats date for ISO 8601 storage: "2027-03-12".
  static String formatIso(DateTime dt) {
    return isoFormat.format(dt);
  }

  /// Parses date from ISO string "YYYY-MM-DD" or falls back to DateTime.tryParse.
  static DateTime parseDate(dynamic value) {
    if (value is DateTime) return toDateOnly(value);
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return toDateOnly(parsed);
    }
    return toDateOnly(DateTime.now());
  }
}
