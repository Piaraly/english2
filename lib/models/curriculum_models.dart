class CurriculumPlan {
  const CurriculumPlan({
    required this.title,
    required this.principles,
    required this.speakingLadder,
    required this.routines,
    required this.months,
    required this.levels,
  });

  final String title;
  final List<PlanPrinciple> principles;
  final List<String> speakingLadder;
  final Map<String, List<RoutineBlock>> routines;
  final List<PlanMonth> months;
  final List<CurriculumLevel> levels;

  factory CurriculumPlan.fromJson(Map<String, dynamic> json) {
    final routineMap = <String, List<RoutineBlock>>{};
    final rawRoutines = Map<String, dynamic>.from(json['routines'] as Map);
    for (final entry in rawRoutines.entries) {
      routineMap[entry.key] = (entry.value as List)
          .map((item) => RoutineBlock.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }
    return CurriculumPlan(
      title: json['title'] as String,
      principles: (json['principles'] as List)
          .map((item) => PlanPrinciple.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      speakingLadder: List<String>.from(json['speaking_ladder'] as List),
      routines: routineMap,
      months: (json['months'] as List)
          .map((item) => PlanMonth.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      levels: (json['levels'] as List)
          .map((item) => CurriculumLevel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }
}

class PlanPrinciple {
  const PlanPrinciple({required this.title, required this.body});

  final String title;
  final String body;

  factory PlanPrinciple.fromJson(Map<String, dynamic> json) => PlanPrinciple(
        title: json['title'] as String,
        body: json['body'] as String,
      );
}

class RoutineBlock {
  const RoutineBlock({required this.label, required this.minutes});

  final String label;
  final int minutes;

  factory RoutineBlock.fromJson(Map<String, dynamic> json) => RoutineBlock(
        label: json['label'] as String,
        minutes: json['minutes'] as int,
      );
}

class PlanMonth {
  const PlanMonth({
    required this.month,
    required this.focus,
    required this.milestone,
  });

  final int month;
  final String focus;
  final String milestone;

  factory PlanMonth.fromJson(Map<String, dynamic> json) => PlanMonth(
        month: json['month'] as int,
        focus: json['focus'] as String,
        milestone: json['milestone'] as String,
      );
}

class CurriculumLevel {
  const CurriculumLevel({
    required this.code,
    required this.name,
    required this.months,
    required this.target,
    required this.pronunciation,
    required this.skills,
    required this.units,
  });

  final String code;
  final String name;
  final String months;
  final String target;
  final List<String> pronunciation;
  final Map<String, String> skills;
  final List<CurriculumUnit> units;

  factory CurriculumLevel.fromJson(Map<String, dynamic> json) {
    final rawSkills = Map<String, dynamic>.from(json['skills'] as Map);
    return CurriculumLevel(
      code: json['code'] as String,
      name: json['name'] as String,
      months: json['months'] as String,
      target: json['target'] as String,
      pronunciation: List<String>.from(json['pronunciation'] as List),
      skills: rawSkills.map((key, value) => MapEntry(key, value as String)),
      units: (json['units'] as List)
          .map((item) => CurriculumUnit.fromJson(
                levelCode: json['code'] as String,
                json: Map<String, dynamic>.from(item as Map),
              ))
          .toList(),
    );
  }
}

class CurriculumUnit {
  const CurriculumUnit({
    required this.levelCode,
    required this.number,
    required this.grammar,
    required this.vocabulary,
  });

  final String levelCode;
  final int number;
  final List<String> grammar;
  final List<String> vocabulary;

  String get id => '$levelCode-$number';
  String get title => '$levelCode • Unidade $number';

  factory CurriculumUnit.fromJson({
    required String levelCode,
    required Map<String, dynamic> json,
  }) =>
      CurriculumUnit(
        levelCode: levelCode,
        number: json['number'] as int,
        grammar: List<String>.from(json['grammar'] as List),
        vocabulary: List<String>.from(json['vocabulary'] as List),
      );
}
