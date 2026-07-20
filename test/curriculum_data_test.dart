import 'dart:convert';
import 'dart:io';

import 'package:english_forge/models/curriculum_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('curriculum asset contains the complete A1-C2 roadmap', () async {
    final raw = await File('assets/data/curriculum.json').readAsString();
    final plan = CurriculumPlan.fromJson(
      Map<String, dynamic>.from(jsonDecode(raw) as Map),
    );

    expect(plan.levels.map((level) => level.code).toList(),
        ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']);
    expect(
      plan.levels.fold<int>(0, (sum, level) => sum + level.units.length),
      65,
    );
    expect(plan.months.length, 8);
    expect(plan.speakingLadder.length, greaterThanOrEqualTo(7));
    expect(plan.routines['minimum'], isNotEmpty);
    expect(plan.routines['ideal'], isNotEmpty);
  });

  test('each unit has grammar or vocabulary content and a unique id', () async {
    final raw = await File('assets/data/curriculum.json').readAsString();
    final plan = CurriculumPlan.fromJson(
      Map<String, dynamic>.from(jsonDecode(raw) as Map),
    );
    final units = plan.levels.expand((level) => level.units).toList();

    expect(units.map((unit) => unit.id).toSet().length, units.length);
    for (final unit in units) {
      expect(unit.grammar.isNotEmpty || unit.vocabulary.isNotEmpty, isTrue,
          reason: '${unit.id} must contain study content');
    }
  });
}
