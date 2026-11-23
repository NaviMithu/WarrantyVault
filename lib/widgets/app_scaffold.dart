import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import 'offline_banner.dart';

class AppScaffold extends StatelessWidget {
  final Widget child;
  final int selectedIndex;

  const AppScaffold({
    super.key,
    required this.child,
    required this.selectedIndex,
  });

  void _onItemTapped(BuildContext context, int index) {
    if (index == 0) {
      context.go('/dashboard');
    } else if (index == 1) {
      context.push('/add');
    } else if (index == 2) {
      context.go('/batteries');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 1. Dashboard Tab
                InkWell(
                  onTap: () => _onItemTapped(context, 0),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          selectedIndex == 0 ? Icons.dashboard_rounded : Icons.dashboard_outlined,
                          color: selectedIndex == 0
                              ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                              : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Dashboard',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: selectedIndex == 0 ? FontWeight.w600 : FontWeight.w500,
                            color: selectedIndex == 0
                                ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Center Large Circular "+" Button
                InkWell(
                  onTap: () => _onItemTapped(context, 1),
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? AppColors.primaryDark : AppColors.primaryLight).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      size: 32,
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    ),
                  ),
                ),

                // 3. All Batteries Tab
                InkWell(
                  onTap: () => _onItemTapped(context, 2),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          selectedIndex == 2 ? Icons.view_list_rounded : Icons.view_list_outlined,
                          color: selectedIndex == 2
                              ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                              : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'All Batteries',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: selectedIndex == 2 ? FontWeight.w600 : FontWeight.w500,
                            color: selectedIndex == 2
                                ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
