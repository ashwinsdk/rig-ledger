import 'package:hive_flutter/hive_flutter.dart';

part 'tombstone.g.dart';

/// Records a deleted entity so remote devices can apply the deletion during sync.
@HiveType(typeId: 10)
class Tombstone extends HiveObject {
  /// The UUID of the deleted entity
  @HiveField(0)
  String entityId;

  /// The Hive box / collection name (e.g. 'ledger_entries', 'agents')
  @HiveField(1)
  String collection;

  /// When the deletion happened
  @HiveField(2)
  DateTime deletedAt;

  Tombstone({
    required this.entityId,
    required this.collection,
    required this.deletedAt,
  });

  Map<String, dynamic> toJson() => {
        'entityId': entityId,
        'collection': collection,
        'deletedAt': deletedAt.toIso8601String(),
      };

  factory Tombstone.fromJson(Map<String, dynamic> json) => Tombstone(
        entityId: json['entityId'] as String,
        collection: json['collection'] as String,
        deletedAt: DateTime.parse(json['deletedAt'] as String),
      );
}
