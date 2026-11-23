import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_vault/core/constants/app_constants.dart';

void main() {
  test('App branding and package name consistency', () {
    expect(AppConstants.appName, 'WarrantyVault');
    expect(AppConstants.packageName, 'com.warrantyvault.app');
    expect(AppConstants.defaultCompanies.length, 7);
  });
}
