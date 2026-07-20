class RecordingEntry {
  const RecordingEntry({
    this.id,
    required this.path,
    required this.title,
    this.prompt = '',
    this.durationSeconds = 0,
    required this.createdAt,
    this.level = 'A1',
    this.selfScore = 0,
    this.notes = '',
  });

  final int? id;
  final String path;
  final String title;
  final String prompt;
  final int durationSeconds;
  final DateTime createdAt;
  final String level;
  final int selfScore;
  final String notes;

  RecordingEntry copyWith({
    int? id,
    String? title,
    String? prompt,
    int? durationSeconds,
    String? level,
    int? selfScore,
    String? notes,
  }) =>
      RecordingEntry(
        id: id ?? this.id,
        path: path,
        title: title ?? this.title,
        prompt: prompt ?? this.prompt,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        createdAt: createdAt,
        level: level ?? this.level,
        selfScore: selfScore ?? this.selfScore,
        notes: notes ?? this.notes,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'path': path,
        'title': title,
        'prompt': prompt,
        'duration_seconds': durationSeconds,
        'created_at': createdAt.toIso8601String(),
        'level': level,
        'self_score': selfScore,
        'notes': notes,
      };

  factory RecordingEntry.fromMap(Map<String, Object?> map) => RecordingEntry(
        id: map['id'] as int?,
        path: map['path'] as String,
        title: map['title'] as String,
        prompt: (map['prompt'] as String?) ?? '',
        durationSeconds: map['duration_seconds'] as int,
        createdAt: DateTime.parse(map['created_at'] as String),
        level: (map['level'] as String?) ?? 'A1',
        selfScore: map['self_score'] as int,
        notes: (map['notes'] as String?) ?? '',
      );
}
