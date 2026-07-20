import '../../models/study_log.dart';

class ProgressMath {
  const ProgressMath._();

  static int streak(List<StudyLog> logs, {DateTime? today}) {
    if (logs.isEmpty) return 0;
    final anchor = _dateOnly(today ?? DateTime.now());
    final days = logs.map((log) => _dateOnly(log.date)).toSet();
    var cursor = anchor;
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var value = 0;
    while (days.contains(cursor)) {
      value += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return value;
  }

  static int totalMinutes(List<StudyLog> logs) => logs.fold(0, (sum, item) => sum + item.minutes);

  static int totalXp(List<StudyLog> logs) => logs.fold(0, (sum, item) => sum + item.xp);

  static Map<DateTime, int> minutesByDay(List<StudyLog> logs) {
    final result = <DateTime, int>{};
    for (final log in logs) {
      final key = _dateOnly(log.date);
      result[key] = (result[key] ?? 0) + log.minutes;
    }
    return result;
  }

  static DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);
}
