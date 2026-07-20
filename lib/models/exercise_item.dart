class ExerciseItem {
  const ExerciseItem({
    this.id,
    required this.prompt,
    required this.answer,
    this.type = 'translation',
    this.level = 'A1',
    this.category = 'Geral',
    this.explanation = '',
    this.completedCount = 0,
    this.correctCount = 0,
    required this.createdAt,
  });

  final int? id;
  final String prompt;
  final String answer;
  final String type;
  final String level;
  final String category;
  final String explanation;
  final int completedCount;
  final int correctCount;
  final DateTime createdAt;

  ExerciseItem copyWith({
    int? id,
    String? prompt,
    String? answer,
    String? type,
    String? level,
    String? category,
    String? explanation,
    int? completedCount,
    int? correctCount,
  }) =>
      ExerciseItem(
        id: id ?? this.id,
        prompt: prompt ?? this.prompt,
        answer: answer ?? this.answer,
        type: type ?? this.type,
        level: level ?? this.level,
        category: category ?? this.category,
        explanation: explanation ?? this.explanation,
        completedCount: completedCount ?? this.completedCount,
        correctCount: correctCount ?? this.correctCount,
        createdAt: createdAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'prompt': prompt,
        'answer': answer,
        'type': type,
        'level': level,
        'category': category,
        'explanation': explanation,
        'completed_count': completedCount,
        'correct_count': correctCount,
        'created_at': createdAt.toIso8601String(),
      };

  factory ExerciseItem.fromMap(Map<String, Object?> map) => ExerciseItem(
        id: map['id'] as int?,
        prompt: map['prompt'] as String,
        answer: map['answer'] as String,
        type: (map['type'] as String?) ?? 'translation',
        level: (map['level'] as String?) ?? 'A1',
        category: (map['category'] as String?) ?? 'Geral',
        explanation: (map['explanation'] as String?) ?? '',
        completedCount: map['completed_count'] as int,
        correctCount: map['correct_count'] as int,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
