import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final databasePath = await getDatabasesPath();
    final path = p.join(databasePath, 'english_forge.db');
    _database = await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _createSchema,
    );
    return _database!;
  }

  Future<void> _createSchema(Database db, int version) async {
    await db.transaction((txn) async {
      await txn.execute('''
        CREATE TABLE study_events (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          type TEXT NOT NULL,
          scheduled_at TEXT NOT NULL,
          duration_minutes INTEGER NOT NULL,
          completed INTEGER NOT NULL DEFAULT 0,
          notes TEXT NOT NULL DEFAULT '',
          curriculum_unit_id TEXT,
          created_at TEXT NOT NULL
        )
      ''');
      await txn.execute('''
        CREATE TABLE vocabulary (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          term TEXT NOT NULL,
          meaning TEXT NOT NULL,
          example TEXT NOT NULL DEFAULT '',
          category TEXT NOT NULL DEFAULT 'Geral',
          tags TEXT NOT NULL DEFAULT '',
          created_at TEXT NOT NULL,
          due_at TEXT NOT NULL,
          interval_days INTEGER NOT NULL DEFAULT 0,
          ease REAL NOT NULL DEFAULT 2.5,
          repetitions INTEGER NOT NULL DEFAULT 0,
          lapses INTEGER NOT NULL DEFAULT 0,
          archived INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await txn.execute('''
        CREATE TABLE recordings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          path TEXT NOT NULL,
          title TEXT NOT NULL,
          prompt TEXT NOT NULL DEFAULT '',
          duration_seconds INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          level TEXT NOT NULL DEFAULT 'A1',
          self_score INTEGER NOT NULL DEFAULT 0,
          notes TEXT NOT NULL DEFAULT ''
        )
      ''');
      await txn.execute('''
        CREATE TABLE materials (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          path TEXT NOT NULL,
          kind TEXT NOT NULL,
          skill TEXT NOT NULL,
          status TEXT NOT NULL,
          level TEXT NOT NULL,
          progress REAL NOT NULL DEFAULT 0,
          last_position_ms INTEGER NOT NULL DEFAULT 0,
          notes TEXT NOT NULL DEFAULT '',
          created_at TEXT NOT NULL
        )
      ''');
      await txn.execute('''
        CREATE TABLE quizzes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          level TEXT NOT NULL DEFAULT 'A1',
          description TEXT NOT NULL DEFAULT '',
          created_at TEXT NOT NULL
        )
      ''');
      await txn.execute('''
        CREATE TABLE quiz_questions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          quiz_id INTEGER NOT NULL,
          prompt TEXT NOT NULL,
          options_json TEXT NOT NULL,
          answer TEXT NOT NULL,
          explanation TEXT NOT NULL DEFAULT '',
          type TEXT NOT NULL DEFAULT 'multiple_choice',
          FOREIGN KEY (quiz_id) REFERENCES quizzes(id) ON DELETE CASCADE
        )
      ''');
      await txn.execute('''
        CREATE TABLE quiz_attempts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          quiz_id INTEGER NOT NULL,
          score INTEGER NOT NULL,
          total INTEGER NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (quiz_id) REFERENCES quizzes(id) ON DELETE CASCADE
        )
      ''');
      await txn.execute('''
        CREATE TABLE exercises (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          prompt TEXT NOT NULL,
          answer TEXT NOT NULL,
          type TEXT NOT NULL DEFAULT 'translation',
          level TEXT NOT NULL DEFAULT 'A1',
          category TEXT NOT NULL DEFAULT 'Geral',
          explanation TEXT NOT NULL DEFAULT '',
          completed_count INTEGER NOT NULL DEFAULT 0,
          correct_count INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL
        )
      ''');
      await txn.execute('''
        CREATE TABLE curriculum_progress (
          unit_id TEXT PRIMARY KEY,
          completed INTEGER NOT NULL DEFAULT 0,
          score INTEGER NOT NULL DEFAULT 0,
          updated_at TEXT NOT NULL
        )
      ''');
      await txn.execute('''
        CREATE TABLE study_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          minutes INTEGER NOT NULL,
          skill TEXT NOT NULL,
          xp INTEGER NOT NULL,
          source TEXT NOT NULL,
          notes TEXT NOT NULL DEFAULT ''
        )
      ''');
      await txn.execute('''
        CREATE TABLE study_debts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          planned_minutes INTEGER NOT NULL,
          completed_minutes INTEGER NOT NULL,
          outstanding_minutes INTEGER NOT NULL,
          status TEXT NOT NULL DEFAULT 'open',
          reason TEXT NOT NULL DEFAULT ''
        )
      ''');
      await txn.execute('''
        CREATE TABLE player_bookmarks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          material_id INTEGER NOT NULL,
          position_ms INTEGER NOT NULL,
          label TEXT NOT NULL,
          note TEXT NOT NULL DEFAULT '',
          FOREIGN KEY (material_id) REFERENCES materials(id) ON DELETE CASCADE
        )
      ''');
      await txn.execute('CREATE INDEX idx_events_date ON study_events(scheduled_at)');
      await txn.execute('CREATE INDEX idx_vocab_due ON vocabulary(due_at)');
      await txn.execute('CREATE INDEX idx_logs_date ON study_logs(date)');
      await _seed(txn);
    });
  }

  Future<void> _seed(Transaction txn) async {
    final now = DateTime.now().toIso8601String();
    final quizId = await txn.insert('quizzes', {
      'title': 'Diagnóstico rápido A1',
      'level': 'A1',
      'description': 'Um quiz inicial editável para testar a base.',
      'created_at': now,
    });
    final questions = [
      {
        'quiz_id': quizId,
        'prompt': 'Choose the correct sentence.',
        'options_json': '["She is a student.","She are a student.","She be a student."]',
        'answer': 'She is a student.',
        'explanation': 'Use is with she, he and it.',
        'type': 'multiple_choice',
      },
      {
        'quiz_id': quizId,
        'prompt': 'What is the plural of child?',
        'options_json': '["childs","children","childes"]',
        'answer': 'children',
        'explanation': 'Children is an irregular plural.',
        'type': 'multiple_choice',
      },
      {
        'quiz_id': quizId,
        'prompt': 'Complete: I ___ from Mozambique.',
        'options_json': '["am","is","are"]',
        'answer': 'am',
        'explanation': 'The verb be with I is am.',
        'type': 'multiple_choice',
      },
    ];
    for (final question in questions) {
      await txn.insert('quiz_questions', question);
    }

    final exercises = [
      {
        'prompt': 'Translate: Eu estudo inglês todos os dias.',
        'answer': 'I study English every day.',
        'type': 'translation',
        'level': 'A1',
        'category': 'Simple present',
        'explanation': 'Use the base verb with I and the frequency phrase every day.',
        'created_at': now,
      },
      {
        'prompt': 'Complete: She ___ watching a series now.',
        'answer': 'is',
        'type': 'fill_blank',
        'level': 'A2',
        'category': 'Present progressive',
        'explanation': 'Present progressive uses be + verb-ing.',
        'created_at': now,
      },
      {
        'prompt': 'Rewrite using the present perfect: I finished the exercise.',
        'answer': 'I have finished the exercise.',
        'type': 'rewrite',
        'level': 'B1',
        'category': 'Present perfect',
        'explanation': 'Use have + past participle with I.',
        'created_at': now,
      },
    ];
    for (final exercise in exercises) {
      await txn.insert('exercises', {
        ...exercise,
        'completed_count': 0,
        'correct_count': 0,
      });
    }
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
