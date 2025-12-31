import 'package:hive/hive.dart';

part 'bit_entry.g.dart';

@HiveType(typeId: 7)
class BitEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String vehicleId;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  String billNumber; // Numeric only

  @HiveField(4)
  String type; // '6.5inch', '7.25inch', '7.5inch', '9inch', '9.5inch'

  @HiveField(5)
  String bitId;

  @HiveField(6)
  int count;

  @HiveField(7)
  double rate;

  @HiveField(8)
  double total;

  @HiveField(9)
  double paid;

  @HiveField(10)
  double pending;

  @HiveField(11)
  double balance;

  @HiveField(12)
  DateTime? paidDate;

  @HiveField(13)
  String? notes;

  @HiveField(14)
  DateTime createdAt;

  @HiveField(15)
  DateTime updatedAt;

  BitEntry({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.billNumber,
    required this.type,
    required this.bitId,
    required this.count,
    required this.rate,
    required this.total,
    required this.paid,
    required this.pending,
    required this.balance,
    this.paidDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  static const List<String> bitTypes = [
    '6.5inch',
    '7.25inch',
    '7.5inch',
    '9inch',
    '9.5inch'
  ];

  /// Calculate total
  static double calculateTotal(int count, double rate) {
    return count * rate;
  }

  /// Calculate pending
  static double calculatePending(double total, double paid) {
    return total - paid;
  }

  BitEntry copyWith({
    String? id,
    String? vehicleId,
    DateTime? date,
    String? billNumber,
    String? type,
    String? bitId,
    int? count,
    double? rate,
    double? total,
    double? paid,
    double? pending,
    double? balance,
    DateTime? paidDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BitEntry(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      date: date ?? this.date,
      billNumber: billNumber ?? this.billNumber,
      type: type ?? this.type,
      bitId: bitId ?? this.bitId,
      count: count ?? this.count,
      rate: rate ?? this.rate,
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
      'type': type,
      'bitId': bitId,
      'count': count,
      'rate': rate,
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

  factory BitEntry.fromJson(Map<String, dynamic> map) {
    return BitEntry(
      id: map['id'] as String,
      vehicleId: map['vehicleId'] as String,
      date: DateTime.parse(map['date'] as String),
      billNumber: map['billNumber'] as String,
      type: map['type'] as String,
      bitId: map['bitId'] as String,
      count: map['count'] as int,
      rate: (map['rate'] as num).toDouble(),
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
      type,
      bitId,
      count.toString(),
      rate.toString(),
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
    'Type',
    'Bit ID',
    'Count',
    'Rate',
    'Total',
    'Paid',
    'Pending',
    'Balance',
    'Paid Date',
    'Notes',
  ];
}
