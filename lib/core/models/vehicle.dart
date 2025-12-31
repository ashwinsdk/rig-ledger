import 'package:hive/hive.dart';

part 'vehicle.g.dart';

enum VehicleType { mainBore, sideBore }

@HiveType(typeId: 4)
class Vehicle extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int vehicleTypeIndex; // 0 = mainBore, 1 = sideBore

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  DateTime updatedAt;

  Vehicle({
    required this.id,
    required this.name,
    required this.vehicleTypeIndex,
    required this.createdAt,
    required this.updatedAt,
  });

  VehicleType get vehicleType =>
      vehicleTypeIndex == 0 ? VehicleType.mainBore : VehicleType.sideBore;

  set vehicleType(VehicleType type) {
    vehicleTypeIndex = type == VehicleType.mainBore ? 0 : 1;
  }

  Vehicle copyWith({
    String? id,
    String? name,
    int? vehicleTypeIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      name: name ?? this.name,
      vehicleTypeIndex: vehicleTypeIndex ?? this.vehicleTypeIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'vehicleTypeIndex': vehicleTypeIndex,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Vehicle.fromJson(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'] as String,
      name: map['name'] as String,
      vehicleTypeIndex: map['vehicleTypeIndex'] as int? ?? 0,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
