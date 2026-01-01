import 'package:hive/hive.dart';
import 'type_detail.dart';

part 'pvc_entry.g.dart';

@HiveType(typeId: 6)
class PvcEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String vehicleId;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  String billNumber; // Numeric only

  @HiveField(4)
  String
      type; // '7inch', '8inch', '10inch', 'MS' - kept for backward compatibility

  @HiveField(5)
  int count; // Kept for backward compatibility

  @HiveField(6)
  double rate; // Kept for backward compatibility

  @HiveField(7)
  double total;

  @HiveField(8)
  double paid;

  @HiveField(9)
  double pending;

  @HiveField(10)
  double balance;

  @HiveField(11)
  DateTime? paidDate;

  @HiveField(12)
  String storagePlace;

  @HiveField(13)
  String? notes;

  @HiveField(14)
  DateTime createdAt;

  @HiveField(15)
  DateTime updatedAt;

  /// Multiple types selection (deprecated, use typeDetailsJson)
  @HiveField(16)
  List<String>? types;

  /// JSON-encoded list of type details with count and rate per type
  /// Format: [{"type": "7 inch", "count": 5, "rate": 100.0}, ...]
  @HiveField(17)
  String? typeDetailsJson;

  PvcEntry({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.billNumber,
    required this.type,
    this.types,
    this.typeDetailsJson,
    required this.count,
    required this.rate,
    required this.total,
    required this.paid,
    required this.pending,
    required this.balance,
    this.paidDate,
    required this.storagePlace,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  static const List<String> pvcTypes = ['7 inch', '8 inch', '10 inch', 'MS'];

  /// Get parsed type details
  List<TypeDetail>? get typeDetails => TypeDetail.decodeList(typeDetailsJson);

  /// Set type details (encodes to JSON)
  set typeDetails(List<TypeDetail>? value) {
    typeDetailsJson = TypeDetail.encodeList(value);
  }

  /// Calculate total from type details
  static double calculateTotalFromDetails(List<TypeDetail> details) {
    return TypeDetail.totalAmount(details);
  }

  /// Calculate total count from type details
  static int calculateCountFromDetails(List<TypeDetail> details) {
    return TypeDetail.totalCount(details);
  }

  /// Calculate total
  static double calculateTotal(int count, double rate) {
    return count * rate;
  }

  /// Calculate pending
  static double calculatePending(double total, double paid) {
    return total - paid;
  }

  PvcEntry copyWith({
    String? id,
    String? vehicleId,
    DateTime? date,
    String? billNumber,
    String? type,
    List<String>? types,
    String? typeDetailsJson,
    int? count,
    double? rate,
    double? total,
    double? paid,
    double? pending,
    double? balance,
    DateTime? paidDate,
    String? storagePlace,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PvcEntry(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      date: date ?? this.date,
      billNumber: billNumber ?? this.billNumber,
      type: type ?? this.type,
      types: types ?? this.types,
      typeDetailsJson: typeDetailsJson ?? this.typeDetailsJson,
      count: count ?? this.count,
      rate: rate ?? this.rate,
      total: total ?? this.total,
      paid: paid ?? this.paid,
      pending: pending ?? this.pending,
      balance: balance ?? this.balance,
      paidDate: paidDate ?? this.paidDate,
      storagePlace: storagePlace ?? this.storagePlace,
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
      'types': types,
      'typeDetailsJson': typeDetailsJson,
      'count': count,
      'rate': rate,
      'total': total,
      'paid': paid,
      'pending': pending,
      'balance': balance,
      'paidDate': paidDate?.toIso8601String(),
      'storagePlace': storagePlace,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PvcEntry.fromJson(Map<String, dynamic> map) {
    return PvcEntry(
      id: map['id'] as String,
      vehicleId: map['vehicleId'] as String,
      date: DateTime.parse(map['date'] as String),
      billNumber: map['billNumber'] as String,
      type: map['type'] as String,
      types: map['types'] != null ? List<String>.from(map['types']) : null,
      typeDetailsJson: map['typeDetailsJson'] as String?,
      count: map['count'] as int,
      rate: (map['rate'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      paid: (map['paid'] as num).toDouble(),
      pending: (map['pending'] as num).toDouble(),
      balance: (map['balance'] as num).toDouble(),
      paidDate: map['paidDate'] != null
          ? DateTime.parse(map['paidDate'] as String)
          : null,
      storagePlace: map['storagePlace'] as String,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  /// Get display type - shows types from details or falls back
  String get displayType {
    final details = typeDetails;
    if (details != null && details.isNotEmpty) {
      return TypeDetail.displayTypes(details);
    }
    if (types != null && types!.isNotEmpty) {
      return types!.join(', ');
    }
    return type;
  }

  /// Get detailed breakdown string
  String get displayTypeDetails {
    final details = typeDetails;
    if (details != null && details.isNotEmpty) {
      return TypeDetail.displayDetailed(details);
    }
    return '$type: $count × ₹$rate';
  }

  /// Get total count from type details or fallback
  int get totalCount {
    final details = typeDetails;
    if (details != null && details.isNotEmpty) {
      return TypeDetail.totalCount(details);
    }
    return count;
  }

  /// Get calculated total from type details or fallback
  double get calculatedTotal {
    final details = typeDetails;
    if (details != null && details.isNotEmpty) {
      return TypeDetail.totalAmount(details);
    }
    return total;
  }

  /// Generate CSV rows - one row per type detail
  List<List<String>> toCsvRows() {
    final details = typeDetails;
    if (details != null && details.isNotEmpty) {
      return details
          .map((d) => [
                date.toIso8601String().split('T')[0],
                billNumber,
                d.type,
                d.count.toString(),
                d.rate.toString(),
                d.total.toString(),
                paid.toString(),
                pending.toString(),
                balance.toString(),
                paidDate?.toIso8601String().split('T')[0] ?? '',
                storagePlace,
                notes ?? '',
              ])
          .toList();
    }
    // Fallback for old entries
    return [
      [
        date.toIso8601String().split('T')[0],
        billNumber,
        type,
        count.toString(),
        rate.toString(),
        total.toString(),
        paid.toString(),
        pending.toString(),
        balance.toString(),
        paidDate?.toIso8601String().split('T')[0] ?? '',
        storagePlace,
        notes ?? '',
      ]
    ];
  }

  List<String> toCsvRow() {
    return [
      date.toIso8601String().split('T')[0],
      billNumber,
      displayType,
      totalCount.toString(),
      '', // Rate varies by type
      calculatedTotal.toString(),
      paid.toString(),
      pending.toString(),
      balance.toString(),
      paidDate?.toIso8601String().split('T')[0] ?? '',
      storagePlace,
      notes ?? '',
    ];
  }

  static List<String> csvHeaders = [
    'Date',
    'Bill Number',
    'Type',
    'Count',
    'Rate',
    'Total',
    'Paid',
    'Pending',
    'Balance',
    'Paid Date',
    'Storage Place',
    'Notes',
  ];
}
