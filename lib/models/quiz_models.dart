import 'dart:convert';

class Quiz {
  const Quiz({
    this.id,
    required this.title,
    this.level = 'A1',
    this.description = '',
    required this.createdAt,
    this.questions = const [],
  });

  final int? id;
  final String title;
  final String level;
  final String description;
  final DateTime createdAt;
  final List<QuizQuestion> questions;

  Quiz copyWith({
    int? id,
    String? title,
    String? level,
    String? description,
    List<QuizQuestion>? questions,
  }) =>
      Quiz(
        id: id ?? this.id,
        title: title ?? this.title,
        level: level ?? this.level,
        description: description ?? this.description,
        createdAt: createdAt,
        questions: questions ?? this.questions,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'level': level,
        'description': description,
        'created_at': createdAt.toIso8601String(),
      };

  factory Quiz.fromMap(Map<String, Object?> map, {List<QuizQuestion> questions = const []}) => Quiz(
        id: map['id'] as int?,
        title: map['title'] as String,
        level: (map['level'] as String?) ?? 'A1',
        description: (map['description'] as String?) ?? '',
        createdAt: DateTime.parse(map['created_at'] as String),
        questions: questions,
      );
}

class QuizQuestion {
  const QuizQuestion({
    this.id,
    this.quizId,
    required this.prompt,
    required this.options,
    required this.answer,
    this.explanation = '',
    this.type = 'multiple_choice',
  });

  final int? id;
  final int? quizId;
  final String prompt;
  final List<String> options;
  final String answer;
  final String explanation;
  final String type;

  Map<String, Object?> toMap() => {
        'id': id,
        'quiz_id': quizId,
        'prompt': prompt,
        'options_json': jsonEncode(options),
        'answer': answer,
        'explanation': explanation,
        'type': type,
      };

  factory QuizQuestion.fromMap(Map<String, Object?> map) => QuizQuestion(
        id: map['id'] as int?,
        quizId: map['quiz_id'] as int?,
        prompt: map['prompt'] as String,
        options: List<String>.from(jsonDecode(map['options_json'] as String) as List),
        answer: map['answer'] as String,
        explanation: (map['explanation'] as String?) ?? '',
        type: (map['type'] as String?) ?? 'multiple_choice',
      );
}

class QuizAttempt {
  const QuizAttempt({
    this.id,
    required this.quizId,
    required this.score,
    required this.total,
    required this.createdAt,
  });

  final int? id;
  final int quizId;
  final int score;
  final int total;
  final DateTime createdAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'quiz_id': quizId,
        'score': score,
        'total': total,
        'created_at': createdAt.toIso8601String(),
      };

  factory QuizAttempt.fromMap(Map<String, Object?> map) => QuizAttempt(
        id: map['id'] as int?,
        quizId: map['quiz_id'] as int,
        score: map['score'] as int,
        total: map['total'] as int,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
