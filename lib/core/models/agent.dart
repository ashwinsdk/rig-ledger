import 'package:hive/hive.dart';

part 'agent.g.dart';

@HiveType(typeId: 1)
class Agent extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? phone;

  @HiveField(3)
  String? notes;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime updatedAt;

  @HiveField(6)
  String vehicleId; // Vehicle this agent belongs to

  // v2.0.0: default commission rates (Rs per foot) copied to new bills.
  @HiveField(7, defaultValue: 0.0)
  double depthCommissionRate;

  @HiveField(8, defaultValue: 0.0)
  double pvcCommissionRate;

  @HiveField(9, defaultValue: 0.0)
  double msPipeCommissionRate;

  Agent({
    required this.id,
    required this.name,
    this.phone,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.vehicleId = 'default',
    this.depthCommissionRate = 0,
    this.pvcCommissionRate = 0,
    this.msPipeCommissionRate = 0,
  });

  Agent copyWith({
    String? id,
    String? name,
    String? phone,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? vehicleId,
    double? depthCommissionRate,
    double? pvcCommissionRate,
    double? msPipeCommissionRate,
  }) {
    return Agent(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      vehicleId: vehicleId ?? this.vehicleId,
      depthCommissionRate: depthCommissionRate ?? this.depthCommissionRate,
      pvcCommissionRate: pvcCommissionRate ?? this.pvcCommissionRate,
      msPipeCommissionRate: msPipeCommissionRate ?? this.msPipeCommissionRate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'name': name,
      'phone': phone,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'depthCommissionRate': depthCommissionRate,
      'pvcCommissionRate': pvcCommissionRate,
      'msPipeCommissionRate': msPipeCommissionRate,
    };
  }

  factory Agent.fromMap(Map<String, dynamic> map) {
    return Agent(
      id: map['id'] as String,
      vehicleId: map['vehicleId'] as String? ?? 'default',
      name: map['name'] as String,
      phone: map['phone'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      depthCommissionRate:
          (map['depthCommissionRate'] as num?)?.toDouble() ?? 0,
      pvcCommissionRate: (map['pvcCommissionRate'] as num?)?.toDouble() ?? 0,
      msPipeCommissionRate:
          (map['msPipeCommissionRate'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Agent && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
