import 'package:flutter/material.dart';

class ConfirmDialog {
  /// Shows a confirmation dialog for deleting an entry.
  static Future<bool> showDeleteBattery({
    required BuildContext context,
    required String vehicleNumber,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Battery Entry'),
          content: Text(
            'Delete this battery entry for $vehicleNumber? This cannot be undone.',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
