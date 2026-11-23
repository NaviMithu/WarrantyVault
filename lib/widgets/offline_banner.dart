import 'package:flutter/material.dart';
import '../data/services/sync_service.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: SyncService().isOnlineNotifier,
      builder: (context, isOnline, child) {
        if (isOnline) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          color: const Color(0xFFF59E0B),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off_rounded, size: 14, color: Colors.white),
              SizedBox(width: 6),
              Text(
                'Offline mode — changes saved locally and will sync when reconnected',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
