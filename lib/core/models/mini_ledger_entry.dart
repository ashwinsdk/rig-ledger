import 'package:hive/hive.dart';

part 'mini_ledger_entry.g.dart';

@HiveType(typeId: 9)
class MiniLedgerEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String vehicleId;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  String billNumber; // Numeric only

  @HiveField(4)
  String agentId;

  @HiveField(5)
  String agentName;

  @HiveField(6)
  String address; // One-line city

  @HiveField(7)
  double depth;

  @HiveField(8)
  double depthPerFeetRate;

  @HiveField(9)
  double total; // depth x depthPerFeetRate

  @HiveField(10)
  double receivedCash;

  @HiveField(11)
  double receivedPhonePe;

  @HiveField(12)
  String? phonePeName; // a, b, c

  @HiveField(13)
  double balance;

  @HiveField(14)
  double less;

  @HiveField(15)
  String? notes;

  @HiveField(16)
  DateTime createdAt;

  @HiveField(17)
  DateTime updatedAt;

  MiniLedgerEntry({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.billNumber,
    required this.agentId,
    required this.agentName,
    required this.address,
    required this.depth,
    required this.depthPerFeetRate,
    required this.total,
    required this.receivedCash,
    required this.receivedPhonePe,
    this.phonePeName,
    required this.balance,
    required this.less,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  double get totalReceived => receivedCash + receivedPhonePe;

  /// Calculate total
  static double calculateTotal(double depth, double rate) {
    return depth * rate;
  }

  /// Calculate balance
  static double calculateBalance({
    required double total,
    required double receivedCash,
    required double receivedPhonePe,
    required double less,
  }) {
    return total - receivedCash - receivedPhonePe - less;
  }

  MiniLedgerEntry copyWith({
    String? id,
    String? vehicleId,
    DateTime? date,
    String? billNumber,
    String? agentId,
    String? agentName,
    String? address,
    double? depth,
    double? depthPerFeetRate,
    double? total,
    double? receivedCash,
    double? receivedPhonePe,
    String? phonePeName,
    double? balance,
    double? less,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MiniLedgerEntry(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      date: date ?? this.date,
      billNumber: billNumber ?? this.billNumber,
      agentId: agentId ?? this.agentId,
      agentName: agentName ?? this.agentName,
      address: address ?? this.address,
      depth: depth ?? this.depth,
      depthPerFeetRate: depthPerFeetRate ?? this.depthPerFeetRate,
      total: total ?? this.total,
      receivedCash: receivedCash ?? this.receivedCash,
      receivedPhonePe: receivedPhonePe ?? this.receivedPhonePe,
      phonePeName: phonePeName ?? this.phonePeName,
      balance: balance ?? this.balance,
      less: less ?? this.less,
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
      'agentId': agentId,
      'agentName': agentName,
      'address': address,
      'depth': depth,
      'depthPerFeetRate': depthPerFeetRate,
      'total': total,
      'receivedCash': receivedCash,
      'receivedPhonePe': receivedPhonePe,
      'phonePeName': phonePeName,
      'balance': balance,
      'less': less,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MiniLedgerEntry.fromJson(Map<String, dynamic> map) {
    return MiniLedgerEntry(
      id: map['id'] as String,
      vehicleId: map['vehicleId'] as String,
      date: DateTime.parse(map['date'] as String),
      billNumber: map['billNumber'] as String,
      agentId: map['agentId'] as String,
      agentName: map['agentName'] as String,
      address: map['address'] as String,
      depth: (map['depth'] as num).toDouble(),
      depthPerFeetRate: (map['depthPerFeetRate'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      receivedCash: (map['receivedCash'] as num).toDouble(),
      receivedPhonePe: (map['receivedPhonePe'] as num).toDouble(),
      phonePeName: map['phonePeName'] as String?,
      balance: (map['balance'] as num).toDouble(),
      less: (map['less'] as num).toDouble(),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  List<String> toCsvRow() {
    return [
      date.toIso8601String().split('T')[0],
      billNumber,
      agentName,
      address,
      depth.toString(),
      depthPerFeetRate.toString(),
      total.toString(),
      receivedCash.toString(),
      receivedPhonePe.toString(),
      phonePeName ?? '',
      balance.toString(),
      less.toString(),
      notes ?? '',
    ];
  }

  static List<String> csvHeaders = [
    'Date',
    'Bill Number',
    'Agent Name',
    'Address',
    'Depth',
    'Depth Rate/ft',
    'Total',
    'Received Cash',
    'Received PhonePe',
    'PhonePe Name',
    'Balance',
    'Less',
    'Notes',
  ];
}
