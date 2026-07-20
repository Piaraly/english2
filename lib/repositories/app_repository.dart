import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../core/services/database_service.dart';
import '../models/exercise_item.dart';
import '../models/material_item.dart';
import '../models/player_bookmark.dart';
import '../models/quiz_models.dart';
import '../models/recording_entry.dart';
import '../models/study_debt.dart';
import '../models/study_event.dart';
import '../models/study_log.dart';
import '../models/vocabulary_item.dart';

class AppRepository {
  AppRepository({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService.instance;

  final DatabaseService _databaseService;

  Future<Database> get _db => _databaseService.database;

  Future<List<StudyEvent>> getStudyEvents() async {
    final db = await _db;
    final rows = await db.query('study_events', orderBy: 'scheduled_at ASC');
    return rows.map(StudyEvent.fromMap).toList();
  }

  Future<int> saveStudyEvent(StudyEvent event) async {
    final db = await _db;
    final map = event.toMap()..remove('id');
    if (event.id == null) return db.insert('study_events', map);
    await db.update('study_events', map, where: 'id = ?', whereArgs: [event.id]);
    return event.id!;
  }

  Future<void> deleteStudyEvent(int id) async {
    final db = await _db;
    await db.delete('study_events', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<VocabularyItem>> getVocabulary() async {
    final db = await _db;
    final rows = await db.query('vocabulary', orderBy: 'due_at ASC, term COLLATE NOCASE');
    return rows.map(VocabularyItem.fromMap).toList();
  }

  Future<int> saveVocabulary(VocabularyItem item) async {
    final db = await _db;
    final map = item.toMap()..remove('id');
    if (item.id == null) return db.insert('vocabulary', map);
    await db.update('vocabulary', map, where: 'id = ?', whereArgs: [item.id]);
    return item.id!;
  }

  Future<void> deleteVocabulary(int id) async {
    final db = await _db;
    await db.delete('vocabulary', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<RecordingEntry>> getRecordings() async {
    final db = await _db;
    final rows = await db.query('recordings', orderBy: 'created_at DESC');
    return rows.map(RecordingEntry.fromMap).toList();
  }

  Future<int> saveRecording(RecordingEntry entry) async {
    final db = await _db;
    final map = entry.toMap()..remove('id');
    if (entry.id == null) return db.insert('recordings', map);
    await db.update('recordings', map, where: 'id = ?', whereArgs: [entry.id]);
    return entry.id!;
  }

  Future<void> deleteRecording(int id) async {
    final db = await _db;
    await db.delete('recordings', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<MaterialItem>> getMaterials() async {
    final db = await _db;
    final rows = await db.query('materials', orderBy: 'created_at DESC');
    return rows.map(MaterialItem.fromMap).toList();
  }

  Future<int> saveMaterial(MaterialItem item) async {
    final db = await _db;
    final map = item.toMap()..remove('id');
    if (item.id == null) return db.insert('materials', map);
    await db.update('materials', map, where: 'id = ?', whereArgs: [item.id]);
    return item.id!;
  }

  Future<void> deleteMaterial(int id) async {
    final db = await _db;
    await db.delete('materials', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Quiz>> getQuizzes() async {
    final db = await _db;
    final quizRows = await db.query('quizzes', orderBy: 'created_at DESC');
    final quizzes = <Quiz>[];
    for (final row in quizRows) {
      final quizId = row['id'] as int;
      final questionRows = await db.query(
        'quiz_questions',
        where: 'quiz_id = ?',
        whereArgs: [quizId],
        orderBy: 'id ASC',
      );
      quizzes.add(Quiz.fromMap(
        row,
        questions: questionRows.map(QuizQuestion.fromMap).toList(),
      ));
    }
    return quizzes;
  }

  Future<int> saveQuiz(Quiz quiz) async {
    final db = await _db;
    return db.transaction((txn) async {
      final quizMap = quiz.toMap()..remove('id');
      final quizId = quiz.id == null
          ? await txn.insert('quizzes', quizMap)
          : quiz.id!;
      if (quiz.id != null) {
        await txn.update('quizzes', quizMap, where: 'id = ?', whereArgs: [quiz.id]);
        await txn.delete('quiz_questions', where: 'quiz_id = ?', whereArgs: [quiz.id]);
      }
      for (final question in quiz.questions) {
        final questionMap = question.toMap()
          ..remove('id')
          ..['quiz_id'] = quizId;
        await txn.insert('quiz_questions', questionMap);
      }
      return quizId;
    });
  }

  Future<void> deleteQuiz(int id) async {
    final db = await _db;
    await db.delete('quizzes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> saveQuizAttempt(QuizAttempt attempt) async {
    final db = await _db;
    final map = attempt.toMap()..remove('id');
    await db.insert('quiz_attempts', map);
  }

  Future<List<QuizAttempt>> getQuizAttempts() async {
    final db = await _db;
    final rows = await db.query('quiz_attempts', orderBy: 'created_at DESC');
    return rows.map(QuizAttempt.fromMap).toList();
  }

  Future<List<ExerciseItem>> getExercises() async {
    final db = await _db;
    final rows = await db.query('exercises', orderBy: 'created_at DESC');
    return rows.map(ExerciseItem.fromMap).toList();
  }

  Future<int> saveExercise(ExerciseItem item) async {
    final db = await _db;
    final map = item.toMap()..remove('id');
    if (item.id == null) return db.insert('exercises', map);
    await db.update('exercises', map, where: 'id = ?', whereArgs: [item.id]);
    return item.id!;
  }

  Future<void> deleteExercise(int id) async {
    final db = await _db;
    await db.delete('exercises', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, int>> getCurriculumProgress() async {
    final db = await _db;
    final rows = await db.query('curriculum_progress');
    return {
      for (final row in rows)
        row['unit_id'] as String: row['score'] as int,
    };
  }

  Future<void> setCurriculumProgress(String unitId, int score) async {
    final db = await _db;
    await db.insert(
      'curriculum_progress',
      {
        'unit_id': unitId,
        'completed': score > 0 ? 1 : 0,
        'score': score,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<StudyLog>> getStudyLogs() async {
    final db = await _db;
    final rows = await db.query('study_logs', orderBy: 'date DESC');
    return rows.map(StudyLog.fromMap).toList();
  }

  Future<void> addStudyLog(StudyLog log) async {
    final db = await _db;
    final map = log.toMap()..remove('id');
    await db.insert('study_logs', map);
  }

  Future<List<StudyDebt>> getStudyDebts() async {
    final db = await _db;
    final rows = await db.query('study_debts', orderBy: 'date DESC');
    return rows.map(StudyDebt.fromMap).toList();
  }

  Future<int> saveStudyDebt(StudyDebt debt) async {
    final db = await _db;
    final map = debt.toMap()..remove('id');
    if (debt.id == null) return db.insert('study_debts', map);
    await db.update('study_debts', map, where: 'id = ?', whereArgs: [debt.id]);
    return debt.id!;
  }

  Future<List<PlayerBookmark>> getBookmarks(int materialId) async {
    final db = await _db;
    final rows = await db.query(
      'player_bookmarks',
      where: 'material_id = ?',
      whereArgs: [materialId],
      orderBy: 'position_ms ASC',
    );
    return rows.map(PlayerBookmark.fromMap).toList();
  }

  Future<int> saveBookmark(PlayerBookmark bookmark) async {
    final db = await _db;
    final map = bookmark.toMap()..remove('id');
    return db.insert('player_bookmarks', map);
  }

  Future<void> deleteBookmark(int id) async {
    final db = await _db;
    await db.delete('player_bookmarks', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>> exportAll() async {
    final db = await _db;
    const tables = [
      'study_events',
      'vocabulary',
      'recordings',
      'materials',
      'quizzes',
      'quiz_questions',
      'quiz_attempts',
      'exercises',
      'curriculum_progress',
      'study_logs',
      'study_debts',
      'player_bookmarks',
    ];
    final result = <String, dynamic>{
      'format': 'english_forge_backup_v2',
      'exported_at': DateTime.now().toIso8601String(),
    };
    for (final table in tables) {
      result[table] = await db.query(table);
    }
    return result;
  }

  Future<void> importAll(Map<String, dynamic> backup) async {
    if (backup['format'] != 'english_forge_backup_v2') {
      throw const FormatException('Formato de backup incompatível.');
    }
    final db = await _db;
    const order = [
      'player_bookmarks',
      'quiz_attempts',
      'quiz_questions',
      'study_events',
      'vocabulary',
      'recordings',
      'materials',
      'quizzes',
      'exercises',
      'curriculum_progress',
      'study_logs',
      'study_debts',
    ];
    await db.transaction((txn) async {
      for (final table in order) {
        await txn.delete(table);
      }
      const insertOrder = [
        'study_events',
        'vocabulary',
        'recordings',
        'materials',
        'quizzes',
        'quiz_questions',
        'quiz_attempts',
        'exercises',
        'curriculum_progress',
        'study_logs',
        'study_debts',
        'player_bookmarks',
      ];
      for (final table in insertOrder) {
        final rows = (backup[table] as List? ?? const []);
        for (final rawRow in rows) {
          final row = Map<String, Object?>.from(rawRow as Map);
          await txn.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });
  }

  String encodeBackup(Map<String, dynamic> backup) => const JsonEncoder.withIndent('  ').convert(backup);
}
