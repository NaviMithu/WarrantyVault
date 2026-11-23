/// Utilities for normalizing user inputs.
class NormalizationUtils {
  /// Normalizes a vehicle registration number:
  /// - Converts to uppercase
  /// - Strips all spaces, hyphens, and dots
  /// Example: "tn 37 ab-1234" becomes "TN37AB1234".
  static String normalizeVehicleNumber(String? input) {
    if (input == null) return '';
    return input.replaceAll(RegExp(r'[\s\-\.]'), '').toUpperCase().trim();
  }

  /// Normalizes company names: trimmed, multiple spaces collapsed to one.
  static String normalizeCompanyName(String? input) {
    if (input == null) return '';
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}
