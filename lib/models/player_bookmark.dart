class PlayerBookmark {
  const PlayerBookmark({
    this.id,
    required this.materialId,
    required this.positionMs,
    required this.label,
    this.note = '',
  });

  final int? id;
  final int materialId;
  final int positionMs;
  final String label;
  final String note;

  Map<String, Object?> toMap() => {
        'id': id,
        'material_id': materialId,
        'position_ms': positionMs,
        'label': label,
        'note': note,
      };

  factory PlayerBookmark.fromMap(Map<String, Object?> map) => PlayerBookmark(
        id: map['id'] as int?,
        materialId: map['material_id'] as int,
        positionMs: map['position_ms'] as int,
        label: map['label'] as String,
        note: (map['note'] as String?) ?? '',
      );
}
