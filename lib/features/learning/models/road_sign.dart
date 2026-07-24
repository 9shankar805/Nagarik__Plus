class RoadSign {
  final int id;
  final String title;
  final String? titleNp;
  final String? category;
  final String? description;
  final String? descriptionNp;
  final String? imageUrl;

  RoadSign({
    required this.id,
    required this.title,
    this.titleNp,
    this.category,
    this.description,
    this.descriptionNp,
    this.imageUrl,
  });

  factory RoadSign.fromJson(Map<String, dynamic> json) {
    return RoadSign(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      title: json['title']?.toString() ?? json['name']?.toString() ?? '',
      titleNp: json['title_np']?.toString() ?? json['name_np']?.toString(),
      category: json['category']?.toString() ?? 'Mandatory',
      description: json['description']?.toString(),
      descriptionNp: json['description_np']?.toString(),
      imageUrl: json['image_url']?.toString() ?? json['icon']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'title_np': titleNp,
      'category': category,
      'description': description,
      'description_np': descriptionNp,
      'image_url': imageUrl,
    };
  }
}

class QuizQuestion {
  final int id;
  final String question;
  final String? questionNp;
  final List<String> options;
  final List<String>? optionsNp;
  final int correctOptionIndex;
  final String? explanation;
  final String? category;

  QuizQuestion({
    required this.id,
    required this.question,
    this.questionNp,
    required this.options,
    this.optionsNp,
    required this.correctOptionIndex,
    this.explanation,
    this.category,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final opts = json['options'] is List
        ? (json['options'] as List).map((e) => e.toString()).toList()
        : <String>[];
    final optsNp = json['options_np'] is List
        ? (json['options_np'] as List).map((e) => e.toString()).toList()
        : null;

    return QuizQuestion(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      question: json['question']?.toString() ?? '',
      questionNp: json['question_np']?.toString(),
      options: opts,
      optionsNp: optsNp,
      correctOptionIndex: json['correct_option_index'] is int
          ? json['correct_option_index'] as int
          : (json['correct_answer'] is int ? json['correct_answer'] as int : 0),
      explanation: json['explanation']?.toString(),
      category: json['category']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'question_np': questionNp,
      'options': options,
      'options_np': optionsNp,
      'correct_option_index': correctOptionIndex,
      'explanation': explanation,
      'category': category,
    };
  }
}
