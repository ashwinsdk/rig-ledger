import 'dart:convert';

/// Represents a single type entry with its count and rate
/// Used for PVC, Bit, and Hammer entries that support multi-type selection
class TypeDetail {
  final String type;
  final int count;
  final double rate;

  TypeDetail({
    required this.type,
    required this.count,
    required this.rate,
  });

  double get total => count * rate;

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'count': count,
      'rate': rate,
    };
  }

  factory TypeDetail.fromMap(Map<String, dynamic> map) {
    return TypeDetail(
      type: map['type'] as String,
      count: map['count'] as int,
      rate: (map['rate'] as num).toDouble(),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory TypeDetail.fromJson(String source) =>
      TypeDetail.fromMap(jsonDecode(source));

  /// Encode a list of TypeDetails to JSON string for Hive storage
  static String? encodeList(List<TypeDetail>? details) {
    if (details == null || details.isEmpty) return null;
    return jsonEncode(details.map((d) => d.toMap()).toList());
  }

  /// Decode JSON string to list of TypeDetails
  static List<TypeDetail>? decodeList(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      final List<dynamic> list = jsonDecode(json);
      return list.map((item) => TypeDetail.fromMap(item)).toList();
    } catch (e) {
      return null;
    }
  }

  /// Calculate total count from list of details
  static int totalCount(List<TypeDetail>? details) {
    if (details == null || details.isEmpty) return 0;
    return details.fold(0, (sum, d) => sum + d.count);
  }

  /// Calculate total amount from list of details
  static double totalAmount(List<TypeDetail>? details) {
    if (details == null || details.isEmpty) return 0;
    return details.fold(0.0, (sum, d) => sum + d.total);
  }

  /// Get display string for types (comma-separated)
  static String displayTypes(List<TypeDetail>? details) {
    if (details == null || details.isEmpty) return '';
    return details.map((d) => d.type).join(', ');
  }

  /// Get detailed display string (type: count x rate)
  static String displayDetailed(List<TypeDetail>? details) {
    if (details == null || details.isEmpty) return '';
    return details.map((d) => '${d.type}: ${d.count} × ₹${d.rate}').join('\n');
  }

  @override
  String toString() => 'TypeDetail(type: $type, count: $count, rate: $rate)';

  TypeDetail copyWith({
    String? type,
    int? count,
    double? rate,
  }) {
    return TypeDetail(
      type: type ?? this.type,
      count: count ?? this.count,
      rate: rate ?? this.rate,
    );
  }
}
