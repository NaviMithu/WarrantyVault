class AppConstants {
  static const String appName = 'WarrantyVault';
  static const String packageName = 'com.warrantyvault.app';
  static const String appVersion = '1.0.0 (Build 1)';

  // Pre-seeded battery manufacturers
  static const List<String> defaultCompanies = [
    'Exide',
    'Surya',
    'Amaron',
    'Star',
    'Power',
    'AVM',
    'ABM',
  ];

  // Warranty duration chips
  static const List<int> warrantyMonthChips = [12, 18, 24, 36];
  static const int defaultWarrantyMonths = 24;
  static const int minWarrantyMonths = 1;
  static const int maxWarrantyMonths = 120;

  // Assets
  static const String logoPngPath = 'assets/logo/logo.png';
  static const String logoJpegPath = 'assets/logo/logo.jpeg';
  static const String iconSquarePath = 'assets/logo/icon_square.png';

  // Hive Box names
  static const String batteriesBox = 'batteries_box';
  static const String companiesBox = 'companies_box';
  static const String syncQueueBox = 'sync_queue_box';
  static const String settingsBox = 'settings_box';

  // Days threshold for "Expiring Soon"
  static const int expiringSoonDaysThreshold = 30;
}
