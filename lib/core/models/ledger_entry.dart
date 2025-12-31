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
  double pvcRate; // Legacy - kept for backward compatibility

  @HiveField(11)
  String msPipe; // Type: '6inch'

  @HiveField(12)
  double msPipeRate; // Legacy - kept for backward compatibility

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

  // New fields for updated requirements
  @HiveField(22)
  double pvcInFeet; // PVC feet

  @HiveField(23)
  double pvcPerFeetRate; // PVC rate per feet

  @HiveField(24)
  double msPipeInFeet; // MS Pipe feet

  @HiveField(25)
  double msPipePerFeetRate; // MS Pipe rate per feet

  @HiveField(26)
  double stepRate; // Step rate for depth

  @HiveField(27)
  bool isStepRateManuallyEdited; // Manual override for step rate

  @HiveField(28)
  String vehicleId; // Vehicle this entry belongs to

  @HiveField(29)
  double receivedCash; // Cash payment amount

  @HiveField(30)
  double receivedPhonePe; // PhonePe payment amount

  @HiveField(31)
  String? phonePeName; // PhonePe payer name

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
    this.pvcRate = 0, // Legacy
    required this.msPipe,
    this.msPipeRate = 0, // Legacy
    required this.extraCharges,
    required this.total,
    required this.isTotalManuallyEdited,
    required this.received,
    required this.balance,
    required this.less,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.pvcInFeet = 0,
    this.pvcPerFeetRate = 0,
    this.msPipeInFeet = 0,
    this.msPipePerFeetRate = 0,
    this.stepRate = 0,
    this.isStepRateManuallyEdited = false,
    this.vehicleId = 'default',
    this.receivedCash = 0,
    this.receivedPhonePe = 0,
    this.phonePeName,
  });

  /// Calculate step rate based on depth type and feet
  /// Formula:
  /// 7inch: 0-300ft same rate (d), then cumulative:
  ///   300-400: d+10 per feet, 400-500: d+20 per feet, 500-600: d+30 per feet,
  ///   600-700: d+50 per feet, 700-800: d+70 per feet, 800-900: d+90 per feet,
  ///   900+: continues with +20 per 100ft bracket
  /// 8inch: 0-300ft same rate (d), then cumulative:
  ///   300-400: d+10 per feet, 400-500: d+20 per feet, 500-600: d+40 per feet,
  ///   600-700: d+60 per feet, 700-800: d+80 per feet, 800-900: d+100 per feet,
  ///   900+: continues with +20 per 100ft bracket
  static double calculateStepRate({
    required String depthType,
    required double depthInFeet,
    required double baseRate,
  }) {
    if (depthInFeet <= 300) return 0;

    double totalStepRate = 0;
    final is7inch = depthType == '7inch';

    // Define cumulative rate additions per 100ft bracket
    // For 7inch: +10, +10, +10, +20, +20, +20 (cumulative: 10, 20, 30, 50, 70, 90)
    // For 8inch: +10, +10, +20, +20, +20, +20 (cumulative: 10, 20, 40, 60, 80, 100)
    final List<Map<String, dynamic>> brackets = is7inch
        ? [
            {'start': 300, 'end': 400, 'extraPerFeet': 10}, // d+10
            {'start': 400, 'end': 500, 'extraPerFeet': 20}, // d+20
            {'start': 500, 'end': 600, 'extraPerFeet': 30}, // d+30
            {'start': 600, 'end': 700, 'extraPerFeet': 50}, // d+50
            {'start': 700, 'end': 800, 'extraPerFeet': 70}, // d+70
            {'start': 800, 'end': 900, 'extraPerFeet': 90}, // d+90
          ]
        : [
            {'start': 300, 'end': 400, 'extraPerFeet': 10}, // d+10
            {'start': 400, 'end': 500, 'extraPerFeet': 20}, // d+20
            {'start': 500, 'end': 600, 'extraPerFeet': 40}, // d+40
            {'start': 600, 'end': 700, 'extraPerFeet': 60}, // d+60
            {'start': 700, 'end': 800, 'extraPerFeet': 80}, // d+80
            {'start': 800, 'end': 900, 'extraPerFeet': 100}, // d+100
          ];

    for (final bracket in brackets) {
      final start = bracket['start'] as int;
      final end = bracket['end'] as int;
      final extraPerFeet = bracket['extraPerFeet'] as int;

      if (depthInFeet > start) {
        final feetInBracket = (depthInFeet >= end ? end : depthInFeet) - start;
        if (feetInBracket > 0) {
          totalStepRate += feetInBracket * extraPerFeet;
        }
      }
    }

    // For depth beyond 900ft, continue incrementing by +20 per 100ft bracket
    if (depthInFeet > 900) {
      final feetBeyond900 = depthInFeet - 900;
      final lastExtraRate = is7inch ? 90 : 100; // Rate at 800-900 bracket

      // Calculate how many complete 100ft brackets beyond 900
      final completeBrackets = (feetBeyond900 / 100).floor();
      final remainingFeet = feetBeyond900 % 100;

      // Each bracket beyond 900 adds another +20
      for (int i = 0; i < completeBrackets; i++) {
        totalStepRate += 100 * (lastExtraRate + 20 * (i + 1));
      }

      // Remaining feet in the current bracket
      if (remainingFeet > 0) {
        totalStepRate +=
            remainingFeet * (lastExtraRate + 20 * (completeBrackets + 1));
      }
    }

    return totalStepRate;
  }

  /// Calculate total based on new formula
  /// Total = (Depth × Depth per feet rate) + Step rate + (PVC × PVC per feet rate) + (MS pipe × MS pipe per feet rate) + Extra charges
  static double calculateTotal({
    required double depthInFeet,
    required double depthPerFeetRate,
    required double stepRate,
    required double pvcInFeet,
    required double pvcPerFeetRate,
    required double msPipeInFeet,
    required double msPipePerFeetRate,
    required double extraCharges,
  }) {
    return (depthInFeet * depthPerFeetRate) +
        stepRate +
        (pvcInFeet * pvcPerFeetRate) +
        (msPipeInFeet * msPipePerFeetRate) +
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
    double? pvcInFeet,
    double? pvcPerFeetRate,
    double? msPipeInFeet,
    double? msPipePerFeetRate,
    double? stepRate,
    bool? isStepRateManuallyEdited,
    String? vehicleId,
    double? receivedCash,
    double? receivedPhonePe,
    String? phonePeName,
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
      pvcInFeet: pvcInFeet ?? this.pvcInFeet,
      pvcPerFeetRate: pvcPerFeetRate ?? this.pvcPerFeetRate,
      msPipeInFeet: msPipeInFeet ?? this.msPipeInFeet,
      msPipePerFeetRate: msPipePerFeetRate ?? this.msPipePerFeetRate,
      stepRate: stepRate ?? this.stepRate,
      isStepRateManuallyEdited:
          isStepRateManuallyEdited ?? this.isStepRateManuallyEdited,
      vehicleId: vehicleId ?? this.vehicleId,
      receivedCash: receivedCash ?? this.receivedCash,
      receivedPhonePe: receivedPhonePe ?? this.receivedPhonePe,
      phonePeName: phonePeName ?? this.phonePeName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'date': date.toIso8601String(),
      'billNumber': billNumber,
      'agentId': agentId,
      'agentName': agentName,
      'address': address,
      'depth': depth,
      'depthInFeet': depthInFeet,
      'depthPerFeetRate': depthPerFeetRate,
      'stepRate': stepRate,
      'pvc': pvc,
      'pvcInFeet': pvcInFeet,
      'pvcPerFeetRate': pvcPerFeetRate,
      'msPipe': msPipe,
      'msPipeInFeet': msPipeInFeet,
      'msPipePerFeetRate': msPipePerFeetRate,
      'extraCharges': extraCharges,
      'total': total,
      'isTotalManuallyEdited': isTotalManuallyEdited,
      'isStepRateManuallyEdited': isStepRateManuallyEdited,
      'received': received,
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

  factory LedgerEntry.fromMap(Map<String, dynamic> map) {
    return LedgerEntry(
      id: map['id'] as String,
      vehicleId: map['vehicleId'] as String? ?? 'default',
      date: DateTime.parse(map['date'] as String),
      billNumber: map['billNumber'] as String,
      agentId: map['agentId'] as String,
      agentName: map['agentName'] as String,
      address: map['address'] as String,
      depth: map['depth'] as String,
      depthInFeet: (map['depthInFeet'] as num).toDouble(),
      depthPerFeetRate: (map['depthPerFeetRate'] as num).toDouble(),
      stepRate: (map['stepRate'] as num?)?.toDouble() ?? 0,
      pvc: map['pvc'] as String,
      pvcInFeet: (map['pvcInFeet'] as num?)?.toDouble() ?? 0,
      pvcPerFeetRate: (map['pvcPerFeetRate'] as num?)?.toDouble() ?? 0,
      msPipe: map['msPipe'] as String? ?? '6inch',
      msPipeInFeet: (map['msPipeInFeet'] as num?)?.toDouble() ?? 0,
      msPipePerFeetRate: (map['msPipePerFeetRate'] as num?)?.toDouble() ?? 0,
      extraCharges: (map['extraCharges'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      isTotalManuallyEdited: map['isTotalManuallyEdited'] as bool? ?? false,
      isStepRateManuallyEdited:
          map['isStepRateManuallyEdited'] as bool? ?? false,
      received: (map['received'] as num).toDouble(),
      receivedCash: (map['receivedCash'] as num?)?.toDouble() ?? 0,
      receivedPhonePe: (map['receivedPhonePe'] as num?)?.toDouble() ?? 0,
      phonePeName: map['phonePeName'] as String?,
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
      date.toIso8601String().split('T')[0],
      billNumber,
      agentName,
      address,
      depth,
      depthInFeet.toString(),
      depthPerFeetRate.toString(),
      stepRate.toString(),
      pvc,
      pvcInFeet.toString(),
      pvcPerFeetRate.toString(),
      msPipe,
      msPipeInFeet.toString(),
      msPipePerFeetRate.toString(),
      extraCharges.toString(),
      total.toString(),
      received.toString(),
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
    'Depth Type',
    'Depth (feet)',
    'Depth Rate/ft',
    'Step Rate',
    'PVC Type',
    'PVC (feet)',
    'PVC Rate/ft',
    'MS Pipe Type',
    'MS Pipe (feet)',
    'MS Pipe Rate/ft',
    'Extra Charges',
    'Total',
    'Received',
    'Balance',
    'Less',
    'Notes',
  ];
}
