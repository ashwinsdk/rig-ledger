import 'package:hive/hive.dart';

part 'cash_entry.g.dart';

@HiveType(typeId: 3)
class CashEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String bookId; // FK to CashBook.id

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  double amount; // always >= 0, rounded to 2 decimals

  @HiveField(4)
  bool isCashIn;

  @HiveField(5)
  String notes;

  @HiveField(6)
  String? description; // "Description / Category"

  @HiveField(7)
  List<String>? attachmentPaths; // up to 3

  @HiveField(8)
  String? itemsJson; // JSON list of item, quantity, unit, rate

  @HiveField(9)
  bool isDeleted; // trash flag

  @HiveField(10)
  DateTime? deletedAt;

  @HiveField(11)
  String? transferGroupId; // links the two rows of a transfer

  @HiveField(12)
  int? importedLegacyId; // row id in the reference app backup

  @HiveField(13)
  DateTime createdAt;

  @HiveField(14)
  DateTime updatedAt;

  @HiveField(15)
  String? bookNameSnapshot; // book name at trash time

  @HiveField(16)
  String? sourceType; // 'ledger_payment' when created from a bill payment

  @HiveField(17)
  String? sourceId; // LedgerEntry.id of the bill

  @HiveField(18)
  String? sourcePaymentId; // payment log id

  /// Rig (Vehicle.id) the entry belongs to (v2.0.4). Optional when typed by
  /// hand; set automatically for income linked from a bill payment (the
  /// bill's rig). Null on older entries.
  @HiveField(19)
  String? vehicleId;

  CashEntry({
    required this.id,
    required this.bookId,
    required this.date,
    required this.amount,
    required this.isCashIn,
    this.notes = '',
    this.description,
    this.attachmentPaths,
    this.itemsJson,
    this.isDeleted = false,
    this.deletedAt,
    this.transferGroupId,
    this.importedLegacyId,
    required this.createdAt,
    required this.updatedAt,
    this.bookNameSnapshot,
    this.sourceType,
    this.sourceId,
    this.sourcePaymentId,
    this.vehicleId,
  });

  /// Signed amount: positive for cash in, negative for cash out.
  double get signedAmount => isCashIn ? amount : -amount;

  CashEntry copyWith({
    String? id,
    String? bookId,
    DateTime? date,
    double? amount,
    bool? isCashIn,
    String? notes,
    String? description,
    List<String>? attachmentPaths,
    String? itemsJson,
    bool? isDeleted,
    DateTime? deletedAt,
    String? transferGroupId,
    int? importedLegacyId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? bookNameSnapshot,
    String? sourceType,
    String? sourceId,
    String? sourcePaymentId,
    String? vehicleId,
    bool clearVehicle = false,
  }) {
    return CashEntry(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      isCashIn: isCashIn ?? this.isCashIn,
      notes: notes ?? this.notes,
      description: description ?? this.description,
      attachmentPaths: attachmentPaths ?? this.attachmentPaths,
      itemsJson: itemsJson ?? this.itemsJson,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      transferGroupId: transferGroupId ?? this.transferGroupId,
      importedLegacyId: importedLegacyId ?? this.importedLegacyId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      bookNameSnapshot: bookNameSnapshot ?? this.bookNameSnapshot,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      sourcePaymentId: sourcePaymentId ?? this.sourcePaymentId,
      vehicleId: clearVehicle ? null : (vehicleId ?? this.vehicleId),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'date': date.toIso8601String(),
      'amount': amount,
      'isCashIn': isCashIn,
      'notes': notes,
      'description': description,
      'attachmentPaths': attachmentPaths,
      'itemsJson': itemsJson,
      'isDeleted': isDeleted,
      'deletedAt': deletedAt?.toIso8601String(),
      'transferGroupId': transferGroupId,
      'importedLegacyId': importedLegacyId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'bookNameSnapshot': bookNameSnapshot,
      'sourceType': sourceType,
      'sourceId': sourceId,
      'sourcePaymentId': sourcePaymentId,
      'vehicleId': vehicleId,
    };
  }

  factory CashEntry.fromJson(Map<String, dynamic> map) {
    return CashEntry(
      id: map['id'] as String,
      bookId: map['bookId'] as String,
      date: DateTime.parse(map['date'] as String),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      isCashIn: map['isCashIn'] as bool? ?? true,
      notes: map['notes'] as String? ?? '',
      description: map['description'] as String?,
      attachmentPaths:
          (map['attachmentPaths'] as List?)?.map((e) => e as String).toList(),
      itemsJson: map['itemsJson'] as String?,
      isDeleted: map['isDeleted'] as bool? ?? false,
      deletedAt: map['deletedAt'] != null
          ? DateTime.parse(map['deletedAt'] as String)
          : null,
      transferGroupId: map['transferGroupId'] as String?,
      importedLegacyId: map['importedLegacyId'] as int?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      bookNameSnapshot: map['bookNameSnapshot'] as String?,
      sourceType: map['sourceType'] as String?,
      sourceId: map['sourceId'] as String?,
      sourcePaymentId: map['sourcePaymentId'] as String?,
      vehicleId: map['vehicleId'] as String?,
    );
  }
}
