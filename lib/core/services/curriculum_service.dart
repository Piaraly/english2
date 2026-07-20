import 'dart:convert';

import 'package:flutter/services.dart';

import '../../models/curriculum_models.dart';

class CurriculumService {
  Future<CurriculumPlan> load() async {
    final raw = await rootBundle.loadString('assets/data/curriculum.json');
    return CurriculumPlan.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
