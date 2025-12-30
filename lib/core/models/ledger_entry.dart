import 'package:hive/hive.dart';

part 'ledger_entry.g.dart';

@HiveType(typeId: 0)
class LedgerEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  String billNumber;

  @HiveField(3)
  String agentId;

  @HiveField(4)
  String agentName;

  @HiveField(5)
  String address;

  @HiveField(6)
  String depth; // '7inch' or '8inch'

  @HiveField(7)
  double depthInFeet;

  @HiveField(8)
  double depthPerFeetRate;

  @HiveField(9)
  String pvc; // '7inch' or '8inch'

  @HiveField(10)
  double pvcRate;

  @HiveField(11)
  String msPipe;

  @HiveField(12)
  double msPipeRate;

  @HiveField(13)
  double extraCharges;

  @HiveField(14)
  double total;

  @HiveField(15)
  bool isTotalManuallyEdited;

  @HiveField(16)
  double received;

  @HiveField(17)
  double balance;

  @HiveField(18)
  double less;

  @HiveField(19)
  String? notes;

  @HiveField(20)
  DateTime createdAt;

  @HiveField(21)
  DateTime updatedAt;

  LedgerEntry({
    required this.id,
    required this.date,
    required this.billNumber,
    required this.agentId,
    required this.agentName,
    required this.address,
    required this.depth,
    required this.depthInFeet,
    required this.depthPerFeetRate,
    required this.pvc,
    required this.pvcRate,
    required this.msPipe,
    required this.msPipeRate,
    required this.extraCharges,
    required this.total,
    required this.isTotalManuallyEdited,
    required this.received,
    required this.balance,
    required this.less,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Calculate total based on formula
  static double calculateTotal({
    required double depthInFeet,
    required double depthPerFeetRate,
    required double pvcRate,
    required double msPipeRate,
    required double extraCharges,
  }) {
    return (depthInFeet * depthPerFeetRate) +
        pvcRate +
        msPipeRate +
        extraCharges;
  }

  /// Calculate balance based on formula
  static double calculateBalance({
    required double total,
    required double received,
    required double less,
  }) {
    return total - received - less;
  }

  LedgerEntry copyWith({
    String? id,
    DateTime? date,
    String? billNumber,
    String? agentId,
    String? agentName,
    String? address,
    String? depth,
    double? depthInFeet,
    double? depthPerFeetRate,
    String? pvc,
    double? pvcRate,
    String? msPipe,
    double? msPipeRate,
    double? extraCharges,
    double? total,
    bool? isTotalManuallyEdited,
    double? received,
    double? balance,
    double? less,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LedgerEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      billNumber: billNumber ?? this.billNumber,
      agentId: agentId ?? this.agentId,
      agentName: agentName ?? this.agentName,
      address: address ?? this.address,
      depth: depth ?? this.depth,
      depthInFeet: depthInFeet ?? this.depthInFeet,
      depthPerFeetRate: depthPerFeetRate ?? this.depthPerFeetRate,
      pvc: pvc ?? this.pvc,
      pvcRate: pvcRate ?? this.pvcRate,
      msPipe: msPipe ?? this.msPipe,
      msPipeRate: msPipeRate ?? this.msPipeRate,
      extraCharges: extraCharges ?? this.extraCharges,
      total: total ?? this.total,
      isTotalManuallyEdited:
          isTotalManuallyEdited ?? this.isTotalManuallyEdited,
      received: received ?? this.received,
      balance: balance ?? this.balance,
      less: less ?? this.less,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'billNumber': billNumber,
      'agentId': agentId,
      'agentName': agentName,
      'address': address,
      'depth': depth,
      'depthInFeet': depthInFeet,
      'depthPerFeetRate': depthPerFeetRate,
      'pvc': pvc,
      'pvcRate': pvcRate,
      'msPipe': msPipe,
      'msPipeRate': msPipeRate,
      'extraCharges': extraCharges,
      'total': total,
      'isTotalManuallyEdited': isTotalManuallyEdited,
      'received': received,
      'balance': balance,
      'less': less,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory LedgerEntry.fromMap(Map<String, dynamic> map) {
    return LedgerEntry(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      billNumber: map['billNumber'] as String,
      agentId: map['agentId'] as String,
      agentName: map['agentName'] as String,
      address: map['address'] as String,
      depth: map['depth'] as String,
      depthInFeet: (map['depthInFeet'] as num).toDouble(),
      depthPerFeetRate: (map['depthPerFeetRate'] as num).toDouble(),
      pvc: map['pvc'] as String,
      pvcRate: (map['pvcRate'] as num).toDouble(),
      msPipe: map['msPipe'] as String,
      msPipeRate: (map['msPipeRate'] as num).toDouble(),
      extraCharges: (map['extraCharges'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      isTotalManuallyEdited: map['isTotalManuallyEdited'] as bool? ?? false,
      received: (map['received'] as num).toDouble(),
      balance: (map['balance'] as num).toDouble(),
      less: (map['less'] as num).toDouble(),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  /// Convert to CSV row
  List<String> toCsvRow() {
    return [
      date.toIso8601String().split('T')[0], // YYYY-MM-DD
      billNumber,
      agentName,
      address,
      depth,
      depthInFeet.toString(),
      depthPerFeetRate.toString(),
      pvc,
      pvcRate.toString(),
      msPipe,
      msPipeRate.toString(),
      extraCharges.toString(),
      total.toString(),
      received.toString(),
      balance.toString(),
      less.toString(),
    ];
  }

  static List<String> csvHeaders = [
    'Date',
    'Bill number',
    'Agent name',
    'Address',
    'Depth',
    'Depth in feet',
    'Depth per feet rate',
    'PVC',
    'PVC rate',
    'MS pipe',
    'MS pipe rate',
    'Extra-chargers',
    'TOTAL',
    'Received',
    'Balance',
    'Less',
  ];
}
