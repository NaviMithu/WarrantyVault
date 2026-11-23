import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'data/services/hive_service.dart';
import 'data/services/supabase_service.dart';
import 'data/services/sync_service.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Load environment variables safely
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Note: .env file not found or could not be loaded: $e');
  }

  // Initialize local Hive cache
  try {
    await HiveService().init();
  } catch (e) {
    debugPrint('Error initializing Hive: $e');
  }

  // Initialize Supabase and attempt silent background login
  try {
    await SupabaseService().init();
  } catch (e) {
    debugPrint('Error initializing Supabase: $e');
  }

  // Initialize background network sync
  try {
    SyncService().init();
  } catch (e) {
    debugPrint('Error initializing SyncService: $e');
  }

  // Remove native splash screen
  FlutterNativeSplash.remove();

  runApp(
    const ProviderScope(
      child: WarrantyVaultApp(),
    ),
  );
}

class WarrantyVaultApp extends ConsumerWidget {
  const WarrantyVaultApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
