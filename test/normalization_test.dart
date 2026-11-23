import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_vault/core/utils/normalization.dart';

void main() {
  group('Vehicle Number Normalization', () {
    test('Converts lowercase to uppercase and strips spaces and hyphens', () {
      expect(NormalizationUtils.normalizeVehicleNumber('tn 37 ab-1234'), 'TN37AB1234');
    });

    test('Strips multiple spaces and dots', () {
      expect(NormalizationUtils.normalizeVehicleNumber('ka . 01 . mj - 9999'), 'KA01MJ9999');
    });

    test('Handles already normalized input cleanly', () {
      expect(NormalizationUtils.normalizeVehicleNumber('MH12DE1432'), 'MH12DE1432');
    });

    test('Handles null or empty input safely without crashing', () {
      expect(NormalizationUtils.normalizeVehicleNumber(null), '');
      expect(NormalizationUtils.normalizeVehicleNumber(''), '');
      expect(NormalizationUtils.normalizeVehicleNumber('   ---  '), '');
    });
  });

  group('Company Name Normalization', () {
    test('Trims and collapses multiple spaces', () {
      expect(NormalizationUtils.normalizeCompanyName('  Exide   Batteries  '), 'Exide Batteries');
    });

    test('Handles null safely', () {
      expect(NormalizationUtils.normalizeCompanyName(null), '');
    });
  });
}
