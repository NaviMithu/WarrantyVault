import 'package:flutter/material.dart';
import '../../core/utils/status_utils.dart';

class WarrantyProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0 (used / total)
  final BatteryStatus status;
  final double height;

  const WarrantyProgressBar({
    super.key,
    required this.progress,
    required this.status,
    this.height = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackColor = isDark ? Colors.white12 : Colors.black12;

    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: LinearProgressIndicator(
        value: progress.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: trackColor,
        valueColor: AlwaysStoppedAnimation<Color>(status.color),
      ),
    );
  }
}
