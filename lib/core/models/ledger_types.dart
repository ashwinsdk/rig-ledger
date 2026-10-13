import 'dart:convert';

/// The three kinds of type a bill has (v2.0.1: user-defined).
enum LedgerTypeCategory { depth, pvc, ms }

extension LedgerTypeCategoryX on LedgerTypeCategory {
  String get label => switch (this) {
        LedgerTypeCategory.depth => 'Depth types',
        LedgerTypeCategory.pvc => 'PVC types',
        LedgerTypeCategory.ms => 'MS pipe types',
      };

  /// Short name used in messages.
  String get shortName => switch (this) {
        LedgerTypeCategory.depth => 'depth',
        LedgerTypeCategory.pvc => 'PVC',
        LedgerTypeCategory.ms => 'MS pipe',
      };
}

/// The user-editable lists of depth, PVC and MS pipe types.
///
/// Plain class (not a Hive model). Stored as one JSON string in the settings
/// box under `ledgerTypes`, included in backups and merged on Drive sync by
/// [updatedAt] (latest wins). A bill keeps its type as plain text such as
/// `'9inch'`, so old bills never depend on this list; the list only drives the
/// dropdowns, filters and totals.
class LedgerTypes {
  final List<String> depth;
  final List<String> pvc;
  final List<String> ms;

  /// Depth type -> built-in step rate table to use: `'7inch'`, `'8inch'` or
  /// `'none'` (explicitly no step rate, for 7inch and 8inch). A depth type that
  /// is not listed (and is not 7inch or 8inch) has no step rate.
  final Map<String, String> steps;
  final DateTime updatedAt;

  static const defaultDepth = ['7inch', '8inch'];
  static const defaultPvc = ['7inch', '8inch'];
  static const defaultMs = ['6inch'];

  /// Older than any real edit, so a real edit always wins a sync merge.
  static final DateTime _epoch = DateTime(2000);

  const LedgerTypes({
    required this.depth,
    required this.pvc,
    required this.ms,
    this.steps = const {},
    required this.updatedAt,
  });

  factory LedgerTypes.defaults() => LedgerTypes(
        depth: defaultDepth,
        pvc: defaultPvc,
        ms: defaultMs,
        updatedAt: _epoch,
      );

  List<String> forCategory(LedgerTypeCategory c) => switch (c) {
        LedgerTypeCategory.depth => depth,
        LedgerTypeCategory.pvc => pvc,
        LedgerTypeCategory.ms => ms,
      };

  /// The built-in step rate table for [type], or null for no step rate.
  String? stepTableFor(String type) {
    final t = steps[type];
    if (t == 'none') return null;
    if (t == '7inch' || t == '8inch') return t;
    if (type == '7inch' || type == '8inch') return type;
    return null;
  }

  /// The list for [c] plus [current] when it is missing (an old bill whose
  /// type was deleted or never listed must still show in its own dropdown).
  List<String> withCurrent(LedgerTypeCategory c, String? current) {
    final list = forCategory(c);
    if (current == null || current.isEmpty || list.contains(current)) {
      return list;
    }
    return [...list, current];
  }

  LedgerTypes copyWith({
    List<String>? depth,
    List<String>? pvc,
    List<String>? ms,
    Map<String, String>? steps,
    DateTime? updatedAt,
  }) =>
      LedgerTypes(
        depth: depth ?? this.depth,
        pvc: pvc ?? this.pvc,
        ms: ms ?? this.ms,
        steps: steps ?? this.steps,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  LedgerTypes withCategory(LedgerTypeCategory c, List<String> list) =>
      switch (c) {
        LedgerTypeCategory.depth => copyWith(depth: list),
        LedgerTypeCategory.pvc => copyWith(pvc: list),
        LedgerTypeCategory.ms => copyWith(ms: list),
      };

  Map<String, dynamic> toJson() => {
        'depth': depth,
        'pvc': pvc,
        'ms': ms,
        'steps': steps,
        'updatedAt': updatedAt.toIso8601String(),
      };

  String encode() => jsonEncode(toJson());

  /// Tolerant: a missing or damaged value gives the defaults.
  factory LedgerTypes.fromJson(Object? source) {
    try {
      final map = source is String
          ? jsonDecode(source) as Map<String, dynamic>
          : Map<String, dynamic>.from(source as Map);
      List<String> list(String key, List<String> fallback) {
        final v = map[key];
        if (v is! List) return fallback;
        final out = <String>[];
        for (final x in v) {
          if (x is String && x.isNotEmpty && !out.contains(x)) out.add(x);
        }
        return out;
      }

      final steps = <String, String>{};
      final rawSteps = map['steps'];
      if (rawSteps is Map) {
        rawSteps.forEach((k, v) {
          if (k is String && (v == '7inch' || v == '8inch' || v == 'none')) {
            steps[k] = v as String;
          }
        });
      }
      return LedgerTypes(
        depth: list('depth', defaultDepth),
        pvc: list('pvc', defaultPvc),
        ms: list('ms', defaultMs),
        steps: steps,
        updatedAt:
            DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? _epoch,
      );
    } catch (_) {
      return LedgerTypes.defaults();
    }
  }

  /// Turns what the user typed (a number of inches such as `9` or `9.5`) into
  /// the stored name (`'9inch'`, `'9.5inch'`). Returns null when it is not a
  /// positive number up to 99.99.
  static String? nameFromInches(String input) {
    final cleaned = input
        .trim()
        .toLowerCase()
        .replaceAll('inches', '')
        .replaceAll('inch', '')
        .replaceAll('"', '')
        .trim();
    final n = double.tryParse(cleaned);
    if (n == null || n <= 0 || n >= 100) return null;
    final rounded = (n * 100).round() / 100;
    var text = rounded.toStringAsFixed(2);
    text = text.replaceFirst(RegExp(r'\.?0+$'), '');
    return '${text}inch';
  }

  /// The number part for editing: `'9.5inch'` -> `'9.5'`.
  static String inchesOf(String type) => type.replaceAll('inch', '');
}
