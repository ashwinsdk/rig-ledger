import 'dart:convert';

/// One line of a bill (v2.0.2): feet of one depth, PVC or MS pipe type with
/// its own rate and commission rate. A bill can have several lines per
/// category, for example 200 ft of 7inch and 150 ft of 8inch depth.
///
/// Not a Hive model: the list is stored as JSON in [LedgerEntry.linesJson].
class LedgerLine {
  static const String depth = 'depth';
  static const String pvc = 'pvc';
  static const String ms = 'ms';
  static const List<String> categories = [depth, pvc, ms];

  /// 'depth', 'pvc' or 'ms'.
  final String category;

  /// Type name such as '7inch' (a name from the Ledger Types lists).
  final String type;

  final double feet;

  /// Bill rate per foot.
  final double rate;

  /// Commission rate per foot (never part of the bill total).
  final double commissionRate;

  const LedgerLine({
    required this.category,
    required this.type,
    this.feet = 0,
    this.rate = 0,
    this.commissionRate = 0,
  });

  /// feet x rate, rounded to paise.
  double get amount => _round2(feet * rate);

  /// feet x commission rate, rounded to paise.
  double get commission => _round2(feet * commissionRate);

  static double _round2(double v) => (v * 100).round() / 100;

  LedgerLine copyWith({
    String? type,
    double? feet,
    double? rate,
    double? commissionRate,
  }) {
    return LedgerLine(
      category: category,
      type: type ?? this.type,
      feet: feet ?? this.feet,
      rate: rate ?? this.rate,
      commissionRate: commissionRate ?? this.commissionRate,
    );
  }

  Map<String, dynamic> toJson() => {
        'c': category,
        't': type,
        'f': feet,
        'r': rate,
        'k': commissionRate,
      };

  factory LedgerLine.fromJson(Map<String, dynamic> m) => LedgerLine(
        category: m['c'] as String? ?? depth,
        type: m['t'] as String? ?? '',
        feet: (m['f'] as num?)?.toDouble() ?? 0,
        rate: (m['r'] as num?)?.toDouble() ?? 0,
        commissionRate: (m['k'] as num?)?.toDouble() ?? 0,
      );

  /// Empty or broken text gives an empty list.
  static List<LedgerLine> decodeList(String? json) {
    if (json == null || json.isEmpty) return const [];
    try {
      final raw = jsonDecode(json) as List<dynamic>;
      return [
        for (final e in raw)
          LedgerLine.fromJson(Map<String, dynamic>.from(e as Map))
      ];
    } catch (_) {
      return const [];
    }
  }

  static String? encodeList(Iterable<LedgerLine> lines) {
    final list = lines.toList();
    if (list.isEmpty) return null;
    return jsonEncode([for (final l in list) l.toJson()]);
  }

  @override
  bool operator ==(Object other) =>
      other is LedgerLine &&
      other.category == category &&
      other.type == type &&
      other.feet == feet &&
      other.rate == rate &&
      other.commissionRate == commissionRate;

  @override
  int get hashCode => Object.hash(category, type, feet, rate, commissionRate);
}
