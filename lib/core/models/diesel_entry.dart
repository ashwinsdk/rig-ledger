import 'package:hive/hive.dart';

part 'diesel_entry.g.dart';

@HiveType(typeId: 5)
class DieselEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String vehicleId;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  String billNumber; // Numeric only

  @HiveField(4)
  double litre;

  @HiveField(5)
  double rate;

  @HiveField(6)
  double total;

  @HiveField(7)
  double paid;

  @HiveField(8)
  double pending;

  @HiveField(9)
  double balance;

  @HiveField(10)
  DateTime? paidDate;

  @HiveField(11)
  String bunkDetails; // Place - similar to address

  @HiveField(12)
  String? notes;

  @HiveField(13)
  DateTime createdAt;

  @HiveField(14)
  DateTime updatedAt;

  DieselEntry({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.billNumber,
    required this.litre,
    required this.rate,
    required this.total,
    required this.paid,
    required this.pending,
    required this.balance,
    this.paidDate,
    required this.bunkDetails,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Calculate total
  static double calculateTotal(double litre, double rate) {
    return litre * rate;
  }

  /// Calculate pending
  static double calculatePending(double total, double paid) {
    return total - paid;
  }

  DieselEntry copyWith({
    String? id,
    String? vehicleId,
    DateTime? date,
    String? billNumber,
    double? litre,
    double? rate,
    double? total,
    double? paid,
    double? pending,
    double? balance,
    DateTime? paidDate,
    String? bunkDetails,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DieselEntry(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      date: date ?? this.date,
      billNumber: billNumber ?? this.billNumber,
      litre: litre ?? this.litre,
      rate: rate ?? this.rate,
      total: total ?? this.total,
      paid: paid ?? this.paid,
      pending: pending ?? this.pending,
      balance: balance ?? this.balance,
      paidDate: paidDate ?? this.paidDate,
      bunkDetails: bunkDetails ?? this.bunkDetails,
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
      'litre': litre,
      'rate': rate,
      'total': total,
      'paid': paid,
      'pending': pending,
      'balance': balance,
      'paidDate': paidDate?.toIso8601String(),
      'bunkDetails': bunkDetails,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DieselEntry.fromJson(Map<String, dynamic> map) {
    return DieselEntry(
      id: map['id'] as String,
      vehicleId: map['vehicleId'] as String,
      date: DateTime.parse(map['date'] as String),
      billNumber: map['billNumber'] as String,
      litre: (map['litre'] as num).toDouble(),
      rate: (map['rate'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      paid: (map['paid'] as num).toDouble(),
      pending: (map['pending'] as num).toDouble(),
      balance: (map['balance'] as num).toDouble(),
      paidDate: map['paidDate'] != null
          ? DateTime.parse(map['paidDate'] as String)
          : null,
      bunkDetails: map['bunkDetails'] as String,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  List<String> toCsvRow() {
    return [
      date.toIso8601String().split('T')[0],
      billNumber,
      litre.toString(),
      rate.toString(),
      total.toString(),
      paid.toString(),
      pending.toString(),
      balance.toString(),
      paidDate?.toIso8601String().split('T')[0] ?? '',
      bunkDetails,
      notes ?? '',
    ];
  }

  static List<String> csvHeaders = [
    'Date',
    'Bill Number',
    'Litre',
    'Rate',
    'Total',
    'Paid',
    'Pending',
    'Balance',
    'Paid Date',
    'Bunk Details',
    'Notes',
  ];
}
