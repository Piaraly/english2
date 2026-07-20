class StudyDebt {
  const StudyDebt({
    this.id,
    required this.date,
    required this.plannedMinutes,
    required this.completedMinutes,
    required this.outstandingMinutes,
    this.status = 'open',
    this.reason = '',
  });

  final int? id;
  final DateTime date;
  final int plannedMinutes;
  final int completedMinutes;
  final int outstandingMinutes;
  final String status;
  final String reason;

  StudyDebt copyWith({
    int? id,
    int? plannedMinutes,
    int? completedMinutes,
    int? outstandingMinutes,
    String? status,
    String? reason,
  }) =>
      StudyDebt(
        id: id ?? this.id,
        date: date,
        plannedMinutes: plannedMinutes ?? this.plannedMinutes,
        completedMinutes: completedMinutes ?? this.completedMinutes,
        outstandingMinutes: outstandingMinutes ?? this.outstandingMinutes,
        status: status ?? this.status,
        reason: reason ?? this.reason,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'planned_minutes': plannedMinutes,
        'completed_minutes': completedMinutes,
        'outstanding_minutes': outstandingMinutes,
        'status': status,
        'reason': reason,
      };

  factory StudyDebt.fromMap(Map<String, Object?> map) => StudyDebt(
        id: map['id'] as int?,
        date: DateTime.parse(map['date'] as String),
        plannedMinutes: map['planned_minutes'] as int,
        completedMinutes: map['completed_minutes'] as int,
        outstandingMinutes: map['outstanding_minutes'] as int,
        status: (map['status'] as String?) ?? 'open',
        reason: (map['reason'] as String?) ?? '',
      );
}
