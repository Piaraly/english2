class StudyEvent {
  const StudyEvent({
    this.id,
    required this.title,
    required this.type,
    required this.scheduledAt,
    required this.durationMinutes,
    this.completed = false,
    this.notes = '',
    this.curriculumUnitId,
    required this.createdAt,
  });

  final int? id;
  final String title;
  final String type;
  final DateTime scheduledAt;
  final int durationMinutes;
  final bool completed;
  final String notes;
  final String? curriculumUnitId;
  final DateTime createdAt;

  StudyEvent copyWith({
    int? id,
    String? title,
    String? type,
    DateTime? scheduledAt,
    int? durationMinutes,
    bool? completed,
    String? notes,
    String? curriculumUnitId,
  }) =>
      StudyEvent(
        id: id ?? this.id,
        title: title ?? this.title,
        type: type ?? this.type,
        scheduledAt: scheduledAt ?? this.scheduledAt,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        completed: completed ?? this.completed,
        notes: notes ?? this.notes,
        curriculumUnitId: curriculumUnitId ?? this.curriculumUnitId,
        createdAt: createdAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'type': type,
        'scheduled_at': scheduledAt.toIso8601String(),
        'duration_minutes': durationMinutes,
        'completed': completed ? 1 : 0,
        'notes': notes,
        'curriculum_unit_id': curriculumUnitId,
        'created_at': createdAt.toIso8601String(),
      };

  factory StudyEvent.fromMap(Map<String, Object?> map) => StudyEvent(
        id: map['id'] as int?,
        title: map['title'] as String,
        type: map['type'] as String,
        scheduledAt: DateTime.parse(map['scheduled_at'] as String),
        durationMinutes: map['duration_minutes'] as int,
        completed: (map['completed'] as int) == 1,
        notes: (map['notes'] as String?) ?? '',
        curriculumUnitId: map['curriculum_unit_id'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
