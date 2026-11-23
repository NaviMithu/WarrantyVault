import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/batteries_list/batteries_list_screen.dart';
import '../../features/companies/manage_companies_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/detail/battery_detail_screen.dart';
import '../../features/entry_form/entry_form_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../widgets/app_scaffold.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/dashboard',
  routes: [
    // Shell route for persistent bottom navigation (Dashboard + All Batteries)
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        final location = state.uri.path;
        final selectedIndex = location.startsWith('/batteries') ? 2 : 0;
        return AppScaffold(
          selectedIndex: selectedIndex,
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/batteries',
          pageBuilder: (context, state) {
            final filter = state.uri.queryParameters['filter'];
            final sort = state.uri.queryParameters['sort'];
            return NoTransitionPage(
              child: BatteriesListScreen(
                key: ValueKey('batteries_${filter}_$sort'),
                initialFilter: filter,
                initialSort: sort,
              ),
            );
          },
        ),
      ],
    ),

    // Modal & pushed screens
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/add',
      builder: (context, state) => const EntryFormScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/edit/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return EntryFormScreen(batteryId: id);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/battery/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return BatteryDetailScreen(batteryId: id);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/companies',
      builder: (context, state) => const ManageCompaniesScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
