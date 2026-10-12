import 'package:hive/hive.dart';

part 'cash_book.g.dart';

@HiveType(typeId: 2)
class CashBook extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  DateTime createdAt;

  @HiveField(3)
  DateTime updatedAt;

  @HiveField(4)
  int sortOrder;

  @HiveField(5)
  int kind; // 0 = custom book, 1 = receiver book

  CashBook({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.sortOrder = 0,
    this.kind = 0,
  });

  bool get isReceiver => kind == 1;

  CashBook copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? sortOrder,
    int? kind,
  }) {
    return CashBook(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sortOrder: sortOrder ?? this.sortOrder,
      kind: kind ?? this.kind,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'sortOrder': sortOrder,
      'kind': kind,
    };
  }

  factory CashBook.fromJson(Map<String, dynamic> map) {
    return CashBook(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      sortOrder: map['sortOrder'] as int? ?? 0,
      kind: map['kind'] as int? ?? 0,
    );
  }
}
