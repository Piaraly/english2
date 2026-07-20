import 'package:flutter_test/flutter_test.dart';
import 'package:english_forge/core/utils/srs_engine.dart';
import 'package:english_forge/models/vocabulary_item.dart';

void main() {
  const engine = SrsEngine();
  final now = DateTime(2026, 7, 20, 12);

  VocabularyItem card() => VocabularyItem(
        term: 'consistency',
        meaning: 'consistência',
        createdAt: now,
        dueAt: now,
      );

  test('successful first review schedules one day', () {
    final result = engine.review(card(), 5, now: now);
    expect(result.repetitions, 1);
    expect(result.intervalDays, 1);
    expect(result.dueAt, now.add(const Duration(days: 1)));
    expect(result.lapses, 0);
  });

  test('second successful review schedules six days', () {
    final first = engine.review(card(), 5, now: now);
    final second = engine.review(first, 4, now: now);
    expect(second.repetitions, 2);
    expect(second.intervalDays, 6);
  });

  test('failed review resets repetition and records lapse', () {
    final learned = card().copyWith(repetitions: 4, intervalDays: 21);
    final result = engine.review(learned, 1, now: now);
    expect(result.repetitions, 0);
    expect(result.intervalDays, 1);
    expect(result.lapses, 1);
  });
}
