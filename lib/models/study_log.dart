class StudyLog {
  const StudyLog({
    this.id,
    required this.date,
    required this.minutes,
    required this.skill,
    required this.xp,
    required this.source,
    this.notes = '',
  });

  final int? id;
  final DateTime date;
  final int minutes;
  final String skill;
  final int xp;
  final String source;
  final String notes;

  Map<String, Object?> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'minutes': minutes,
        'skill': skill,
        'xp': xp,
        'source': source,
        'notes': notes,
      };

  factory StudyLog.fromMap(Map<String, Object?> map) => StudyLog(
        id: map['id'] as int?,
        date: DateTime.parse(map['date'] as String),
        minutes: map['minutes'] as int,
        skill: map['skill'] as String,
        xp: map['xp'] as int,
        source: map['source'] as String,
        notes: (map['notes'] as String?) ?? '',
      );
}
