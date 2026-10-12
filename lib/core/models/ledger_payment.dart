import 'dart:convert';

/// One payment received on a ledger entry (bill). Not a Hive model: the list
/// is stored as JSON in [LedgerEntry.paymentsJson].
///
/// A payment with a [receiverBookId] has a linked income entry in that book of
/// the Account Ledger (see PaymentLinkService).
class LedgerPayment {
  static const String modeCash = 'cash';
  static const String modePhonePe = 'phonepe';

  final String id;
  final DateTime date;
  final double amount;
  final String mode; // modeCash or modePhonePe
  final String? receiverBookId;
  final String? payerName; // PhonePe sender name
  final String? notes;

  const LedgerPayment({
    required this.id,
    required this.date,
    required this.amount,
    this.mode = modeCash,
    this.receiverBookId,
    this.payerName,
    this.notes,
  });

  bool get isCash => mode != modePhonePe;

  LedgerPayment copyWith({
    DateTime? date,
    double? amount,
    String? mode,
    String? receiverBookId,
    bool clearReceiver = false,
    String? payerName,
    String? notes,
  }) {
    return LedgerPayment(
      id: id,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      mode: mode ?? this.mode,
      receiverBookId:
          clearReceiver ? null : (receiverBookId ?? this.receiverBookId),
      payerName: payerName ?? this.payerName,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'amount': amount,
        'mode': mode,
        'receiverBookId': receiverBookId,
        'payerName': payerName,
        'notes': notes,
      };

  factory LedgerPayment.fromJson(Map<String, dynamic> m) => LedgerPayment(
        id: m['id'] as String,
        date: DateTime.parse(m['date'] as String),
        amount: (m['amount'] as num?)?.toDouble() ?? 0,
        mode: m['mode'] as String? ?? modeCash,
        receiverBookId: m['receiverBookId'] as String?,
        payerName: m['payerName'] as String?,
        notes: m['notes'] as String?,
      );

  static String? encodeList(List<LedgerPayment> list) =>
      list.isEmpty ? null : jsonEncode(list.map((e) => e.toJson()).toList());

  /// Never throws: invalid JSON yields an empty list.
  static List<LedgerPayment> decodeList(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      return (jsonDecode(json) as List)
          .map((e) => LedgerPayment.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static double totalCash(Iterable<LedgerPayment> list) =>
      _sum(list.where((p) => p.isCash));

  static double totalPhonePe(Iterable<LedgerPayment> list) =>
      _sum(list.where((p) => !p.isCash));

  static double _sum(Iterable<LedgerPayment> list) {
    var paise = 0;
    for (final p in list) {
      paise += (p.amount * 100).round();
    }
    return paise / 100;
  }
}
