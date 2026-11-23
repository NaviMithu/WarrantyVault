import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';
import 'date_utils.dart';

enum BatteryStatus {
  active,
  expiringSoon,
  expired;

  String get displayName {
    switch (this) {
      case BatteryStatus.active:
        return 'Active';
      case BatteryStatus.expiringSoon:
        return 'Expiring Soon';
      case BatteryStatus.expired:
        return 'Expired';
    }
  }

  Color get color {
    switch (this) {
      case BatteryStatus.active:
        return AppColors.statusActive;
      case BatteryStatus.expiringSoon:
        return AppColors.statusExpiring;
      case BatteryStatus.expired:
        return AppColors.statusExpired;
    }
  }

  Color backgroundColor(bool isDark) {
    switch (this) {
      case BatteryStatus.active:
        return isDark ? AppColors.statusActiveBgDark : AppColors.statusActiveBgLight;
      case BatteryStatus.expiringSoon:
        return isDark ? AppColors.statusExpiringBgDark : AppColors.statusExpiringBgLight;
      case BatteryStatus.expired:
        return isDark ? AppColors.statusExpiredBgDark : AppColors.statusExpiredBgLight;
    }
  }

  Color textColor(bool isDark) {
    switch (this) {
      case BatteryStatus.active:
        return isDark ? AppColors.statusActiveTextDark : AppColors.statusActiveTextLight;
      case BatteryStatus.expiringSoon:
        return isDark ? AppColors.statusExpiringTextDark : AppColors.statusExpiringTextLight;
      case BatteryStatus.expired:
        return isDark ? AppColors.statusExpiredTextDark : AppColors.statusExpiredTextLight;
    }
  }
}

class StatusUtils {
  /// Evaluates the status of a battery given its [expiryDate].
  /// [today] can be passed for deterministic testing.
  static BatteryStatus classify(DateTime expiryDate, [DateTime? today]) {
    final days = AppDateUtils.daysRemaining(expiryDate, today);
    if (days < 0) {
      return BatteryStatus.expired;
    } else if (days <= AppConstants.expiringSoonDaysThreshold) {
      return BatteryStatus.expiringSoon;
    } else {
      return BatteryStatus.active;
    }
  }

  /// Returns user-friendly status badge text like:
  /// - "240 days left" (Active)
  /// - "Expires in 12 days" / "Expires today" (Expiring Soon)
  /// - "Expired 5 days ago" / "Expired yesterday" (Expired)
  static String getBadgeText(DateTime expiryDate, [DateTime? today]) {
    final days = AppDateUtils.daysRemaining(expiryDate, today);
    if (days < 0) {
      final absDays = days.abs();
      return absDays == 1 ? 'Expired yesterday' : 'Expired $absDays days ago';
    } else if (days == 0) {
      return 'Expires today';
    } else if (days <= AppConstants.expiringSoonDaysThreshold) {
      return days == 1 ? 'Expires in 1 day' : 'Expires in $days days';
    } else {
      return '$days days left';
    }
  }
}
