class MaterialItem {
  const MaterialItem({
    this.id,
    required this.name,
    required this.path,
    required this.kind,
    required this.skill,
    required this.status,
    required this.level,
    this.progress = 0,
    this.lastPositionMs = 0,
    this.notes = '',
    required this.createdAt,
  });

  final int? id;
  final String name;
  final String path;
  final String kind;
  final String skill;
  final String status;
  final String level;
  final double progress;
  final int lastPositionMs;
  final String notes;
  final DateTime createdAt;

  MaterialItem copyWith({
    int? id,
    String? name,
    String? path,
    String? kind,
    String? skill,
    String? status,
    String? level,
    double? progress,
    int? lastPositionMs,
    String? notes,
  }) =>
      MaterialItem(
        id: id ?? this.id,
        name: name ?? this.name,
        path: path ?? this.path,
        kind: kind ?? this.kind,
        skill: skill ?? this.skill,
        status: status ?? this.status,
        level: level ?? this.level,
        progress: progress ?? this.progress,
        lastPositionMs: lastPositionMs ?? this.lastPositionMs,
        notes: notes ?? this.notes,
        createdAt: createdAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'path': path,
        'kind': kind,
        'skill': skill,
        'status': status,
        'level': level,
        'progress': progress,
        'last_position_ms': lastPositionMs,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  factory MaterialItem.fromMap(Map<String, Object?> map) => MaterialItem(
        id: map['id'] as int?,
        name: map['name'] as String,
        path: map['path'] as String,
        kind: map['kind'] as String,
        skill: map['skill'] as String,
        status: map['status'] as String,
        level: map['level'] as String,
        progress: (map['progress'] as num).toDouble(),
        lastPositionMs: map['last_position_ms'] as int,
        notes: (map['notes'] as String?) ?? '',
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
