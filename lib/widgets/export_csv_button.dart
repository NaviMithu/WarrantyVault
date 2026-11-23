import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/battery_repository.dart';

class ExportCsvButton extends ConsumerStatefulWidget {
  final EdgeInsetsGeometry padding;

  const ExportCsvButton({
    super.key,
    this.padding = const EdgeInsets.only(top: 24, bottom: 90),
  });

  @override
  ConsumerState<ExportCsvButton> createState() => _ExportCsvButtonState();
}

class _ExportCsvButtonState extends ConsumerState<ExportCsvButton> {
  bool _isExporting = false;

  Future<void> _handleExport() async {
    setState(() => _isExporting = true);
    final repo = ref.read(batteryRepositoryProvider);
    final success = await repo.exportCsvAndShare();
    if (!mounted) return;
    setState(() => _isExporting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'CSV exported successfully.' : 'Failed to export CSV.',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: widget.padding,
      child: Center(
        child: TextButton.icon(
          onPressed: _isExporting ? null : _handleExport,
          style: TextButton.styleFrom(
            foregroundColor: isDark ? Colors.white60 : Colors.black45,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          icon: _isExporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download_rounded, size: 18),
          label: Text(
            _isExporting ? 'Exporting...' : 'Export CSV',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}
