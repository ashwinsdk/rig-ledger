import 'package:hive/hive.dart';

part 'commission_entry.g.dart';

/// Commission entry for an agent for a specific date range
@HiveType(typeId: 10)
class CommissionEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String agentId;

  @HiveField(2)
  String agentName; // Denormalized for display

  @HiveField(3)
  DateTime startDate;

  @HiveField(4)
  DateTime endDate;

  @HiveField(5)
  double amount;

  @HiveField(6)
  String? notes;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  String vehicleId;

  @HiveField(9)
  bool isPaid;

  CommissionEntry({
    required this.id,
    required this.agentId,
    required this.agentName,
    required this.startDate,
    required this.endDate,
    required this.amount,
    this.notes,
    required this.createdAt,
    this.vehicleId = 'default',
    this.isPaid = false,
  });

  /// Get number of bills in this period for the agent
  int get billCount => 0; // Will be calculated from ledger entries

  CommissionEntry copyWith({
    String? id,
    String? agentId,
    String? agentName,
    DateTime? startDate,
    DateTime? endDate,
    double? amount,
    String? notes,
    DateTime? createdAt,
    String? vehicleId,
    bool? isPaid,
  }) {
    return CommissionEntry(
      id: id ?? this.id,
      agentId: agentId ?? this.agentId,
      agentName: agentName ?? this.agentName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      amount: amount ?? this.amount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      vehicleId: vehicleId ?? this.vehicleId,
      isPaid: isPaid ?? this.isPaid,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'agentId': agentId,
      'agentName': agentName,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'amount': amount,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'vehicleId': vehicleId,
      'isPaid': isPaid,
    };
  }

  factory CommissionEntry.fromMap(Map<String, dynamic> map) {
    return CommissionEntry(
      id: map['id'] as String,
      agentId: map['agentId'] as String,
      agentName: map['agentName'] as String,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      amount: (map['amount'] as num).toDouble(),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      vehicleId: map['vehicleId'] as String? ?? 'default',
      isPaid: map['isPaid'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommissionEntry && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
