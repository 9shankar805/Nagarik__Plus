
class Reminder {
  final int id;
  final String title;
  final String? description;
  final DateTime dateTime;
  final bool isRecurring;
  final String? recurrenceType;
  final bool isCompleted;
  final int? documentId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Reminder({
    required this.id,
    required this.title,
    this.description,
    required this.dateTime,
    this.isRecurring = false,
    this.recurrenceType,
    this.isCompleted = false,
    this.documentId,
    this.createdAt,
    this.updatedAt,
  });

  Reminder copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? dateTime,
    bool? isRecurring,
    String? recurrenceType,
    bool? isCompleted,
    int? documentId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      isCompleted: isCompleted ?? this.isCompleted,
      documentId: documentId ?? this.documentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      dateTime: DateTime.parse(json['date_time'] as String),
      isRecurring: json['is_recurring'] as bool? ?? false,
      recurrenceType: json['recurrence_type'] as String?,
      isCompleted: json['is_completed'] as bool? ?? false,
      documentId: json['document_id'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date_time': dateTime.toIso8601String(),
      'is_recurring': isRecurring,
      'recurrence_type': recurrenceType,
      'is_completed': isCompleted,
      'document_id': documentId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
