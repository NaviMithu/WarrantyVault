import '../../core/utils/date_utils.dart';
import '../../core/utils/normalization.dart';
import '../../core/utils/status_utils.dart';

class BatteryModel {
  final String id;
  final String? userId;
  final String vehicleNumber; // Normalized, e.g. TN37AB1234
  final String ownerName;
  final String? companyId;
  final String companyName;
  final int warrantyMonths;
  final DateTime purchaseDate;
  final DateTime expiryDate;
  final String? ownerPhone;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BatteryModel({
    required this.id,
    this.userId,
    required this.vehicleNumber,
    required this.ownerName,
    this.companyId,
    required this.companyName,
    required this.warrantyMonths,
    required this.purchaseDate,
    required this.expiryDate,
    this.ownerPhone,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory that ensures expiryDate is always calculated properly
  /// and vehicleNumber is always normalized.
  factory BatteryModel.create({
    required String id,
    String? userId,
    required String vehicleNumber,
    required String ownerName,
    String? companyId,
    required String companyName,
    required int warrantyMonths,
    required DateTime purchaseDate,
    String? ownerPhone,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final cleanPurchaseDate = AppDateUtils.toDateOnly(purchaseDate);
    final calculatedExpiry = AppDateUtils.calculateExpiryDate(cleanPurchaseDate, warrantyMonths);
    final now = DateTime.now();

    return BatteryModel(
      id: id,
      userId: userId,
      vehicleNumber: NormalizationUtils.normalizeVehicleNumber(vehicleNumber),
      ownerName: ownerName.trim(),
      companyId: companyId,
      companyName: NormalizationUtils.normalizeCompanyName(companyName),
      warrantyMonths: warrantyMonths,
      purchaseDate: cleanPurchaseDate,
      expiryDate: calculatedExpiry,
      ownerPhone: ownerPhone?.trim().isEmpty == true ? null : ownerPhone?.trim(),
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  BatteryStatus get status => StatusUtils.classify(expiryDate);
  int get daysLeft => AppDateUtils.daysRemaining(expiryDate);
  double get progressUsed => AppDateUtils.warrantyUsedProgress(purchaseDate, expiryDate);
  String get statusBadgeText => StatusUtils.getBadgeText(expiryDate);

  BatteryModel copyWith({
    String? id,
    String? userId,
    String? vehicleNumber,
    String? ownerName,
    String? companyId,
    String? companyName,
    int? warrantyMonths,
    DateTime? purchaseDate,
    DateTime? expiryDate,
    String? ownerPhone,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final updatedPurchase = purchaseDate != null ? AppDateUtils.toDateOnly(purchaseDate) : this.purchaseDate;
    final updatedWarranty = warrantyMonths ?? this.warrantyMonths;
    // Auto-recalculate expiry date if purchase date or warranty months changed
    final updatedExpiry = (purchaseDate != null || warrantyMonths != null)
        ? AppDateUtils.calculateExpiryDate(updatedPurchase, updatedWarranty)
        : (expiryDate != null ? AppDateUtils.toDateOnly(expiryDate) : this.expiryDate);

    return BatteryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vehicleNumber: vehicleNumber != null
          ? NormalizationUtils.normalizeVehicleNumber(vehicleNumber)
          : this.vehicleNumber,
      ownerName: ownerName != null ? ownerName.trim() : this.ownerName,
      companyId: companyId ?? this.companyId,
      companyName: companyName != null
          ? NormalizationUtils.normalizeCompanyName(companyName)
          : this.companyName,
      warrantyMonths: updatedWarranty,
      purchaseDate: updatedPurchase,
      expiryDate: updatedExpiry,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (userId != null) 'user_id': userId,
      'vehicle_number': vehicleNumber,
      'owner_name': ownerName,
      if (companyId != null) 'company_id': companyId,
      'company_name': companyName,
      'warranty_months': warrantyMonths,
      'purchase_date': AppDateUtils.formatIso(purchaseDate),
      'expiry_date': AppDateUtils.formatIso(expiryDate),
      'owner_phone': ownerPhone,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory BatteryModel.fromJson(Map<String, dynamic> json) {
    final purchase = AppDateUtils.parseDate(json['purchase_date']);
    final warrantyMonths = json['warranty_months'] is int
        ? json['warranty_months'] as int
        : int.tryParse(json['warranty_months']?.toString() ?? '24') ?? 24;

    // Recalculate expiry_date to guarantee consistency
    final expiry = json['expiry_date'] != null
        ? AppDateUtils.parseDate(json['expiry_date'])
        : AppDateUtils.calculateExpiryDate(purchase, warrantyMonths);

    return BatteryModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      vehicleNumber: NormalizationUtils.normalizeVehicleNumber(json['vehicle_number']?.toString() ?? ''),
      ownerName: json['owner_name']?.toString() ?? '',
      companyId: json['company_id']?.toString(),
      companyName: NormalizationUtils.normalizeCompanyName(json['company_name']?.toString() ?? ''),
      warrantyMonths: warrantyMonths,
      purchaseDate: purchase,
      expiryDate: expiry,
      ownerPhone: json['owner_phone']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toHiveMap() {
    return {
      'id': id,
      'user_id': userId,
      'vehicle_number': vehicleNumber,
      'owner_name': ownerName,
      'company_id': companyId,
      'company_name': companyName,
      'warranty_months': warrantyMonths,
      'purchase_date': AppDateUtils.formatIso(purchaseDate),
      'expiry_date': AppDateUtils.formatIso(expiryDate),
      'owner_phone': ownerPhone,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory BatteryModel.fromHiveMap(Map<dynamic, dynamic> map) {
    final purchase = AppDateUtils.parseDate(map['purchase_date']);
    final warrantyMonths = map['warranty_months'] is int
        ? map['warranty_months'] as int
        : int.tryParse(map['warranty_months']?.toString() ?? '24') ?? 24;
    final expiry = map['expiry_date'] != null
        ? AppDateUtils.parseDate(map['expiry_date'])
        : AppDateUtils.calculateExpiryDate(purchase, warrantyMonths);

    return BatteryModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString(),
      vehicleNumber: NormalizationUtils.normalizeVehicleNumber(map['vehicle_number']?.toString() ?? ''),
      ownerName: map['owner_name']?.toString() ?? '',
      companyId: map['company_id']?.toString(),
      companyName: NormalizationUtils.normalizeCompanyName(map['company_name']?.toString() ?? ''),
      warrantyMonths: warrantyMonths,
      purchaseDate: purchase,
      expiryDate: expiry,
      ownerPhone: map['owner_phone']?.toString(),
      notes: map['notes']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
