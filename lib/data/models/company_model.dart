class CompanyModel {
  final String id;
  final String name;
  final String? userId;
  final DateTime createdAt;
  final int batteryCount;

  const CompanyModel({
    required this.id,
    required this.name,
    this.userId,
    required this.createdAt,
    this.batteryCount = 0,
  });

  CompanyModel copyWith({
    String? id,
    String? name,
    String? userId,
    DateTime? createdAt,
    int? batteryCount,
  }) {
    return CompanyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      batteryCount: batteryCount ?? this.batteryCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (userId != null) 'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      batteryCount: json['battery_count'] is int ? json['battery_count'] as int : 0,
    );
  }

  Map<String, dynamic> toHiveMap() {
    return {
      'id': id,
      'name': name,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CompanyModel.fromHiveMap(Map<dynamic, dynamic> map) {
    return CompanyModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      userId: map['user_id']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      batteryCount: 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompanyModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name.toLowerCase() == other.name.toLowerCase();

  @override
  int get hashCode => id.hashCode ^ name.toLowerCase().hashCode;
}
