
class NotificationPreferences {
  final bool news;
  final bool documents;
  final bool reminders;
  final bool services;
  final bool ai;

  NotificationPreferences({
    required this.news,
    required this.documents,
    required this.reminders,
    required this.services,
    required this.ai,
  });

  NotificationPreferences copyWith({
    bool? news,
    bool? documents,
    bool? reminders,
    bool? services,
    bool? ai,
  }) {
    return NotificationPreferences(
      news: news ?? this.news,
      documents: documents ?? this.documents,
      reminders: reminders ?? this.reminders,
      services: services ?? this.services,
      ai: ai ?? this.ai,
    );
  }

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      news: json['news'] as bool? ?? true,
      documents: json['documents'] as bool? ?? true,
      reminders: json['reminders'] as bool? ?? true,
      services: json['services'] as bool? ?? true,
      ai: json['ai'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'news': news,
      'documents': documents,
      'reminders': reminders,
      'services': services,
      'ai': ai,
    };
  }
}
