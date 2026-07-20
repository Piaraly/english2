import '../../models/vocabulary_item.dart';

class SrsEngine {
  const SrsEngine();

  VocabularyItem review(VocabularyItem item, int quality, {DateTime? now}) {
    assert(quality >= 0 && quality <= 5);
    final reviewTime = now ?? DateTime.now();
    var repetitions = item.repetitions;
    var interval = item.intervalDays;
    var ease = item.ease;
    var lapses = item.lapses;

    if (quality < 3) {
      repetitions = 0;
      interval = 1;
      lapses += 1;
    } else {
      if (repetitions == 0) {
        interval = 1;
      } else if (repetitions == 1) {
        interval = 6;
      } else {
        interval = (interval * ease).round().clamp(1, 3650).toInt();
      }
      repetitions += 1;
    }

    ease += 0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02);
    ease = ease.clamp(1.3, 3.0).toDouble();

    return item.copyWith(
      dueAt: reviewTime.add(Duration(days: interval)),
      intervalDays: interval,
      ease: ease,
      repetitions: repetitions,
      lapses: lapses,
    );
  }
}
