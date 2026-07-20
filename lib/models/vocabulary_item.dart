class VocabularyItem {
  const VocabularyItem({
    this.id,
    required this.term,
    required this.meaning,
    this.example = '',
    this.category = 'Geral',
    this.tags = '',
    required this.createdAt,
    required this.dueAt,
    this.intervalDays = 0,
    this.ease = 2.5,
    this.repetitions = 0,
    this.lapses = 0,
    this.archived = false,
  });

  final int? id;
  final String term;
  final String meaning;
  final String example;
  final String category;
  final String tags;
  final DateTime createdAt;
  final DateTime dueAt;
  final int intervalDays;
  final double ease;
  final int repetitions;
  final int lapses;
  final bool archived;

  VocabularyItem copyWith({
    int? id,
    String? term,
    String? meaning,
    String? example,
    String? category,
    String? tags,
    DateTime? dueAt,
    int? intervalDays,
    double? ease,
    int? repetitions,
    int? lapses,
    bool? archived,
  }) =>
      VocabularyItem(
        id: id ?? this.id,
        term: term ?? this.term,
        meaning: meaning ?? this.meaning,
        example: example ?? this.example,
        category: category ?? this.category,
        tags: tags ?? this.tags,
        createdAt: createdAt,
        dueAt: dueAt ?? this.dueAt,
        intervalDays: intervalDays ?? this.intervalDays,
        ease: ease ?? this.ease,
        repetitions: repetitions ?? this.repetitions,
        lapses: lapses ?? this.lapses,
        archived: archived ?? this.archived,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'term': term,
        'meaning': meaning,
        'example': example,
        'category': category,
        'tags': tags,
        'created_at': createdAt.toIso8601String(),
        'due_at': dueAt.toIso8601String(),
        'interval_days': intervalDays,
        'ease': ease,
        'repetitions': repetitions,
        'lapses': lapses,
        'archived': archived ? 1 : 0,
      };

  factory VocabularyItem.fromMap(Map<String, Object?> map) => VocabularyItem(
        id: map['id'] as int?,
        term: map['term'] as String,
        meaning: map['meaning'] as String,
        example: (map['example'] as String?) ?? '',
        category: (map['category'] as String?) ?? 'Geral',
        tags: (map['tags'] as String?) ?? '',
        createdAt: DateTime.parse(map['created_at'] as String),
        dueAt: DateTime.parse(map['due_at'] as String),
        intervalDays: map['interval_days'] as int,
        ease: (map['ease'] as num).toDouble(),
        repetitions: map['repetitions'] as int,
        lapses: map['lapses'] as int,
        archived: (map['archived'] as int) == 1,
      );
}
