import 'dart:convert';

/// One step rate table (v2.0.4): beyond [threshold] feet of depth every 100 ft
/// bracket adds an extra rate per foot. [extras] has one value per bracket
/// (threshold to threshold + 100, and so on). After the last bracket each
/// further 100 ft adds [beyondIncrement] more than the one before.
///
/// The built-in tables are the ones the app always had: 7 inch +10, +20, +30,
/// +50, +70, +90 and 8 inch +10, +20, +40, +60, +80, +100 from 300 ft, with
/// +20 for each further 100 ft after 900 ft.
class StepTable {
  final double threshold;
  final List<double> extras;
  final double beyondIncrement;

  const StepTable({
    required this.threshold,
    required this.extras,
    required this.beyondIncrement,
  });

  static const StepTable builtin7 = StepTable(
      threshold: 300, extras: [10, 20, 30, 50, 70, 90], beyondIncrement: 20);
  static const StepTable builtin8 = StepTable(
      threshold: 300, extras: [10, 20, 40, 60, 80, 100], beyondIncrement: 20);

  /// The built-in table for '7inch' or '8inch'.
  static StepTable builtinFor(String table) =>
      table == '7inch' ? builtin7 : builtin8;

  /// Total step rate for [feet] of depth (the extra money, not per foot).
  double calculate(double feet) {
    if (feet <= threshold || extras.isEmpty) return 0;
    var total = 0.0;
    for (var i = 0; i < extras.length; i++) {
      final start = threshold + 100.0 * i;
      final end = start + 100;
      if (feet > start) {
        final inBracket = (feet >= end ? end : feet) - start;
        if (inBracket > 0) total += inBracket * extras[i];
      }
    }
    final beyondStart = threshold + 100.0 * extras.length;
    if (feet > beyondStart) {
      final beyond = feet - beyondStart;
      final last = extras.last;
      final complete = (beyond / 100).floor();
      final remaining = beyond % 100;
      for (var i = 0; i < complete; i++) {
        total += 100 * (last + beyondIncrement * (i + 1));
      }
      if (remaining > 0) {
        total += remaining * (last + beyondIncrement * (complete + 1));
      }
    }
    return total;
  }

  StepTable copyWith(
          {double? threshold, List<double>? extras, double? beyondIncrement}) =>
      StepTable(
        threshold: threshold ?? this.threshold,
        extras: extras ?? this.extras,
        beyondIncrement: beyondIncrement ?? this.beyondIncrement,
      );

  Map<String, dynamic> toJson() => {
        'threshold': threshold,
        'extras': extras,
        'beyond': beyondIncrement,
      };

  factory StepTable.fromJson(Object? raw, StepTable fallback) {
    try {
      final m = raw as Map;
      final extras = [
        for (final e in (m['extras'] as List)) (e as num).toDouble()
      ];
      return StepTable(
        threshold: (m['threshold'] as num).toDouble(),
        extras: extras,
        beyondIncrement: (m['beyond'] as num?)?.toDouble() ?? 0,
      );
    } catch (_) {
      return fallback;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is StepTable &&
      other.threshold == threshold &&
      other.beyondIncrement == beyondIncrement &&
      other.extras.length == extras.length &&
      [for (var i = 0; i < extras.length; i++) other.extras[i] == extras[i]]
          .every((x) => x);

  @override
  int get hashCode =>
      Object.hash(threshold, beyondIncrement, Object.hashAll(extras));
}

/// The 7 inch and 8 inch tables of one rig.
class RigStepRates {
  final StepTable table7;
  final StepTable table8;
  final DateTime updatedAt;

  const RigStepRates({
    this.table7 = StepTable.builtin7,
    this.table8 = StepTable.builtin8,
    required this.updatedAt,
  });

  static final RigStepRates standard = RigStepRates(
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true));

  /// 'standard' tables saved or not: true when both are the built-in ones.
  bool get isStandard =>
      table7 == StepTable.builtin7 && table8 == StepTable.builtin8;

  StepTable table(String name) => name == '7inch' ? table7 : table8;

  RigStepRates copyWith(
          {StepTable? table7, StepTable? table8, DateTime? updatedAt}) =>
      RigStepRates(
        table7: table7 ?? this.table7,
        table8: table8 ?? this.table8,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        't7': table7.toJson(),
        't8': table8.toJson(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory RigStepRates.fromJson(Object? raw) {
    try {
      final m = raw as Map;
      return RigStepRates(
        table7: StepTable.fromJson(m['t7'], StepTable.builtin7),
        table8: StepTable.fromJson(m['t8'], StepTable.builtin8),
        updatedAt: DateTime.parse(m['updatedAt'] as String),
      );
    } catch (_) {
      return RigStepRates.standard;
    }
  }
}

/// Step rate tables for every rig, stored as JSON in the settings box under
/// `stepRates`. A rig without an entry uses the built-in tables.
class StepRates {
  final Map<String, RigStepRates> byRig;
  const StepRates([this.byRig = const {}]);

  RigStepRates forRig(String vehicleId) =>
      byRig[vehicleId] ?? RigStepRates.standard;

  StepRates withRig(String vehicleId, RigStepRates rates) =>
      StepRates({...byRig, vehicleId: rates});

  StepRates withoutRig(String vehicleId) =>
      StepRates({...byRig}..remove(vehicleId));

  Map<String, dynamic> toJson() =>
      {for (final e in byRig.entries) e.key: e.value.toJson()};

  String encode() => jsonEncode(toJson());

  factory StepRates.fromJson(Object? raw) {
    try {
      final data = raw is String ? jsonDecode(raw) : raw;
      final m = Map<String, dynamic>.from(data as Map);
      return StepRates({
        for (final e in m.entries) e.key: RigStepRates.fromJson(e.value),
      });
    } catch (_) {
      return const StepRates();
    }
  }

  /// Per rig, the side with the newer `updatedAt` wins (used by the Drive
  /// merge). A rig on one side only is kept.
  static StepRates merge(StepRates local, StepRates remote) {
    final out = <String, RigStepRates>{...local.byRig};
    remote.byRig.forEach((id, r) {
      final l = out[id];
      if (l == null || r.updatedAt.isAfter(l.updatedAt)) out[id] = r;
    });
    return StepRates(out);
  }
}
