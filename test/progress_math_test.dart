import 'package:flutter_test/flutter_test.dart';
import 'package:english_forge/core/utils/progress_math.dart';
import 'package:english_forge/models/study_log.dart';

void main() {
  StudyLog log(DateTime date, int minutes) => StudyLog(
        date: date,
        minutes: minutes,
        skill: 'Listening',
        xp: minutes * 2,
        source: 'test',
      );

  test('streak counts consecutive days including today', () {
    final today = DateTime(2026, 7, 20);
    final logs = [
      log(today, 20),
      log(today.subtract(const Duration(days: 1)), 20),
      log(today.subtract(const Duration(days: 2)), 20),
      log(today.subtract(const Duration(days: 4)), 20),
    ];
    expect(ProgressMath.streak(logs, today: today), 3);
  });

  test('streak can anchor on yesterday when today has no study', () {
    final today = DateTime(2026, 7, 20);
    final logs = [
      log(today.subtract(const Duration(days: 1)), 15),
      log(today.subtract(const Duration(days: 2)), 15),
    ];
    expect(ProgressMath.streak(logs, today: today), 2);
  });

  test('minutes are grouped by calendar day', () {
    final day = DateTime(2026, 7, 20);
    final grouped = ProgressMath.minutesByDay([
      log(day.add(const Duration(hours: 8)), 15),
      log(day.add(const Duration(hours: 19)), 25),
    ]);
    expect(grouped[day], 40);
  });
}
