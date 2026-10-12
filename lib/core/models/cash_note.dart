import 'package:hive/hive.dart';

part 'cash_note.g.dart';

@HiveType(typeId: 11)
class CashNote extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  String text;

  @HiveField(3)
  bool isCompleted;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime updatedAt;

  CashNote({
    required this.id,
    required this.date,
    required this.text,
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  CashNote copyWith({
    String? id,
    DateTime? date,
    String? text,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CashNote(
      id: id ?? this.id,
      date: date ?? this.date,
      text: text ?? this.text,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'text': text,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory CashNote.fromJson(Map<String, dynamic> map) {
    return CashNote(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      text: map['text'] as String? ?? '',
      isCompleted: map['isCompleted'] as bool? ?? false,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
