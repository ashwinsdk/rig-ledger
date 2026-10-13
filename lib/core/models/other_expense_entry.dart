import 'package:hive/hive.dart';

part 'other_expense_entry.g.dart';

/// A side ledger expense that is not diesel, PVC, bit or hammer (v2.0.1):
/// food, repairs, labour, and so on. Used by main bore and side bore rigs.
@HiveType(typeId: 12)
class OtherExpenseEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String vehicleId;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  String billNumber; // optional, may be empty

  @HiveField(4)
  String description; // required: what the money was spent on

  @HiveField(5)
  double total;

  @HiveField(6)
  double paid;

  @HiveField(7)
  double pending;

  @HiveField(8)
  double balance;

  @HiveField(9)
  DateTime? paidDate;

  @HiveField(10)
  String? notes;

  @HiveField(11)
  DateTime createdAt;

  @HiveField(12)
  DateTime updatedAt;

  OtherExpenseEntry({
    required this.id,
    required this.vehicleId,
    required this.date,
    this.billNumber = '',
    required this.description,
    required this.total,
    required this.paid,
    required this.pending,
    required this.balance,
    this.paidDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  static double calculatePending(double total, double paid) => total - paid;

  OtherExpenseEntry copyWith({
    String? id,
    String? vehicleId,
    DateTime? date,
    String? billNumber,
    String? description,
    double? total,
    double? paid,
    double? pending,
    double? balance,
    DateTime? paidDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OtherExpenseEntry(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      date: date ?? this.date,
      billNumber: billNumber ?? this.billNumber,
      description: description ?? this.description,
      total: total ?? this.total,
      paid: paid ?? this.paid,
      pending: pending ?? this.pending,
      balance: balance ?? this.balance,
      paidDate: paidDate ?? this.paidDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'date': date.toIso8601String(),
      'billNumber': billNumber,
      'description': description,
      'total': total,
      'paid': paid,
      'pending': pending,
      'balance': balance,
      'paidDate': paidDate?.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory OtherExpenseEntry.fromJson(Map<String, dynamic> map) {
    return OtherExpenseEntry(
      id: map['id'] as String,
      vehicleId: map['vehicleId'] as String,
      date: DateTime.parse(map['date'] as String),
      billNumber: (map['billNumber'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      total: (map['total'] as num).toDouble(),
      paid: (map['paid'] as num).toDouble(),
      pending: (map['pending'] as num).toDouble(),
      balance: (map['balance'] as num).toDouble(),
      paidDate: map['paidDate'] != null
          ? DateTime.parse(map['paidDate'] as String)
          : null,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  List<String> toCsvRow() {
    return [
      date.toIso8601String().split('T')[0],
      billNumber,
      description,
      total.toString(),
      paid.toString(),
      pending.toString(),
      balance.toString(),
      paidDate?.toIso8601String().split('T')[0] ?? '',
      notes ?? '',
    ];
  }

  static List<String> csvHeaders = [
    'Date',
    'Bill Number',
    'Description',
    'Total',
    'Paid',
    'Pending',
    'Balance',
    'Paid Date',
    'Notes',
  ];
}
