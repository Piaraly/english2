import 'dart:io';

import 'package:flutter/material.dart';

import '../core/services/backup_service.dart';
import '../core/services/curriculum_service.dart';
import '../core/services/notification_service.dart';
import '../core/services/settings_service.dart';
import '../core/utils/progress_math.dart';
import '../core/utils/srs_engine.dart';
import '../models/curriculum_models.dart';
import '../models/exercise_item.dart';
import '../models/material_item.dart';
import '../models/player_bookmark.dart';
import '../models/quiz_models.dart';
import '../models/recording_entry.dart';
import '../models/study_debt.dart';
import '../models/study_event.dart';
import '../models/study_log.dart';
import '../models/vocabulary_item.dart';
import '../repositories/app_repository.dart';

class AppController extends ChangeNotifier {
  AppController({
    AppRepository? repository,
    CurriculumService? curriculumService,
    SettingsService? settingsService,
    NotificationService? notificationService,
    BackupService? backupService,
  })  : _repository = repository ?? AppRepository(),
        _curriculumService = curriculumService ?? CurriculumService(),
        _settingsService = settingsService ?? SettingsService(),
        _notificationService = notificationService ?? NotificationService.instance,
        _backupService = backupService ?? BackupService();

  final AppRepository _repository;
  final CurriculumService _curriculumService;
  final SettingsService _settingsService;
  final NotificationService _notificationService;
  final BackupService _backupService;
  final SrsEngine _srs = const SrsEngine();

  bool loading = true;
  bool onboardingComplete = false;
  String currentLevel = 'A1';
  String routineMode = 'minimum';
  int dailyMinutes = 55;
  TimeOfDay reminderTime = const TimeOfDay(hour: 19, minute: 0);
  ThemeMode themeMode = ThemeMode.system;
  DateTime startedAt = DateTime.now();

  late CurriculumPlan curriculum;
  List<StudyEvent> events = [];
  List<VocabularyItem> vocabulary = [];
  List<RecordingEntry> recordings = [];
  List<MaterialItem> materials = [];
  List<Quiz> quizzes = [];
  List<QuizAttempt> quizAttempts = [];
  List<ExerciseItem> exercises = [];
  Map<String, int> curriculumProgress = {};
  List<StudyLog> logs = [];
  List<StudyDebt> debts = [];

  String? errorMessage;

  Future<void> initialize() async {
    loading = true;
    notifyListeners();
    try {
      curriculum = await _curriculumService.load();
      onboardingComplete = await _settingsService.onboardingComplete;
      currentLevel = await _settingsService.currentLevel;
      routineMode = await _settingsService.routineMode;
      dailyMinutes = await _settingsService.dailyMinutes;
      reminderTime = await _settingsService.reminderTime;
      themeMode = await _settingsService.themeMode;
      startedAt = await _settingsService.getOrCreateStartedAt();
      await refreshData(reconcile: true);
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshData({bool reconcile = false}) async {
    events = await _repository.getStudyEvents();
    vocabulary = await _repository.getVocabulary();
    recordings = await _repository.getRecordings();
    materials = await _repository.getMaterials();
    quizzes = await _repository.getQuizzes();
    quizAttempts = await _repository.getQuizAttempts();
    exercises = await _repository.getExercises();
    curriculumProgress = await _repository.getCurriculumProgress();
    logs = await _repository.getStudyLogs();
    debts = await _repository.getStudyDebts();
    if (reconcile) await _reconcileDebts();
    notifyListeners();
  }

  int get totalMinutes => ProgressMath.totalMinutes(logs);
  int get totalXp => ProgressMath.totalXp(logs);
  int get streak => ProgressMath.streak(logs);
  int get openDebtMinutes => debts
      .where((item) => item.status == 'open')
      .fold(0, (sum, item) => sum + item.outstandingMinutes);
  int get absenceDays => debts.where((item) => item.outstandingMinutes == item.plannedMinutes).length;
  int get dueVocabularyCount => vocabulary.where((item) => !item.archived && !item.dueAt.isAfter(DateTime.now())).length;
  int get completedUnits => curriculumProgress.values.where((score) => score > 0).length;
  int get totalUnits => curriculum.levels.fold(0, (sum, level) => sum + level.units.length);
  double get curriculumCompletion => totalUnits == 0 ? 0 : completedUnits / totalUnits;

  List<StudyEvent> eventsForDay(DateTime day) => events.where((event) {
        final value = event.scheduledAt;
        return value.year == day.year && value.month == day.month && value.day == day.day;
      }).toList();

  List<StudyLog> logsForDay(DateTime day) => logs.where((log) {
        final value = log.date;
        return value.year == day.year && value.month == day.month && value.day == day.day;
      }).toList();

  CurriculumLevel get selectedLevel => curriculum.levels.firstWhere(
        (level) => level.code == currentLevel,
        orElse: () => curriculum.levels.first,
      );

  CurriculumUnit? get nextUnit {
    for (final level in curriculum.levels) {
      for (final unit in level.units) {
        if ((curriculumProgress[unit.id] ?? 0) == 0) return unit;
      }
    }
    return null;
  }

  List<RoutineBlock> get currentRoutine => curriculum.routines[routineMode] ?? const [];

  Future<void> finishOnboarding({
    required String level,
    required String mode,
    required TimeOfDay reminder,
  }) async {
    currentLevel = level;
    routineMode = mode;
    reminderTime = reminder;
    dailyMinutes = (curriculum.routines[mode] ?? const [])
        .fold(0, (sum, item) => sum + item.minutes);
    onboardingComplete = true;
    await _settingsService.setCurrentLevel(level);
    await _settingsService.setRoutineMode(mode);
    await _settingsService.setReminderTime(reminder);
    await _settingsService.setDailyMinutes(dailyMinutes);
    await _settingsService.setOnboardingComplete(true);
    await scheduleDailyReminder();
    notifyListeners();
  }

  Future<void> setLevel(String level) async {
    currentLevel = level;
    await _settingsService.setCurrentLevel(level);
    notifyListeners();
  }

  Future<void> setRoutineMode(String mode) async {
    routineMode = mode;
    dailyMinutes = (curriculum.routines[mode] ?? const [])
        .fold(0, (sum, item) => sum + item.minutes);
    await _settingsService.setRoutineMode(mode);
    await _settingsService.setDailyMinutes(dailyMinutes);
    notifyListeners();
  }

  Future<void> setDailyMinutes(int value) async {
    dailyMinutes = value;
    await _settingsService.setDailyMinutes(value);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode value) async {
    themeMode = value;
    await _settingsService.setThemeMode(value);
    notifyListeners();
  }

  Future<void> setReminderTime(TimeOfDay value) async {
    reminderTime = value;
    await _settingsService.setReminderTime(value);
    await scheduleDailyReminder();
    notifyListeners();
  }

  Future<void> scheduleDailyReminder() async {
    await _notificationService.requestPermission();
    await _notificationService.scheduleDaily(
      id: 9001,
      hour: reminderTime.hour,
      minute: reminderTime.minute,
      title: 'EnglishForge • sessão mínima',
      body: 'Faça apenas o próximo bloco. Nunca falte dois dias seguidos.',
    );
  }

  Future<void> saveEvent(StudyEvent event, {bool scheduleNotification = false}) async {
    await _repository.saveStudyEvent(event);
    if (scheduleNotification && event.scheduledAt.isAfter(DateTime.now())) {
      await _notificationService.requestPermission();
      await _notificationService.scheduleOneTime(
        id: event.scheduledAt.millisecondsSinceEpoch.remainder(2147483647),
        dateTime: event.scheduledAt,
        title: 'EnglishForge • ${event.type}',
        body: event.title,
      );
    }
    await refreshData();
  }

  Future<void> toggleEvent(StudyEvent event) async {
    final updated = event.copyWith(completed: !event.completed);
    await _repository.saveStudyEvent(updated);
    if (!event.completed) {
      await logStudy(
        minutes: event.durationMinutes,
        skill: event.type,
        source: 'calendar',
        notes: event.title,
      );
    } else {
      await refreshData();
    }
  }

  Future<void> deleteEvent(StudyEvent event) async {
    if (event.id == null) return;
    await _repository.deleteStudyEvent(event.id!);
    await refreshData();
  }

  Future<void> logStudy({
    required int minutes,
    required String skill,
    required String source,
    String notes = '',
  }) async {
    final xp = _xpFor(minutes, source);
    await _repository.addStudyLog(StudyLog(
      date: DateTime.now(),
      minutes: minutes,
      skill: skill,
      xp: xp,
      source: source,
      notes: notes,
    ));
    await _repayDebt(minutes);
    await refreshData();
  }

  int _xpFor(int minutes, String source) {
    final bonus = source == 'speaking' ? 8 : source == 'quiz' ? 5 : 0;
    return (minutes * 2 + bonus).clamp(5, 250).toInt();
  }

  Future<void> _reconcileDebts() async {
    final today = DateTime.now();
    final start = DateTime(startedAt.year, startedAt.month, startedAt.day);
    final end = DateTime(today.year, today.month, today.day);
    final existingDates = debts.map((item) => _dateKey(item.date)).toSet();
    var cursor = start;
    var changed = false;
    while (cursor.isBefore(end)) {
      final key = _dateKey(cursor);
      if (!existingDates.contains(key)) {
        final completed = logsForDay(cursor).fold(0, (sum, item) => sum + item.minutes);
        final outstanding = (dailyMinutes - completed).clamp(0, dailyMinutes).toInt();
        if (outstanding > 0) {
          await _repository.saveStudyDebt(StudyDebt(
            date: cursor,
            plannedMinutes: dailyMinutes,
            completedMinutes: completed,
            outstandingMinutes: outstanding,
            status: 'open',
          ));
          changed = true;
        }
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    if (changed) debts = await _repository.getStudyDebts();
  }

  Future<void> _repayDebt(int minutes) async {
    var available = minutes;
    final open = debts.where((item) => item.status == 'open').toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    for (final debt in open) {
      if (available <= 0) break;
      final payment = available.clamp(0, debt.outstandingMinutes).toInt();
      final remaining = debt.outstandingMinutes - payment;
      await _repository.saveStudyDebt(debt.copyWith(
        outstandingMinutes: remaining,
        status: remaining == 0 ? 'paid' : 'open',
      ));
      available -= payment;
    }
  }

  Future<void> updateDebtReason(StudyDebt debt, String reason) async {
    await _repository.saveStudyDebt(debt.copyWith(reason: reason));
    await refreshData();
  }

  Future<void> saveVocabulary(VocabularyItem item) async {
    await _repository.saveVocabulary(item);
    await refreshData();
  }

  Future<void> deleteVocabulary(VocabularyItem item) async {
    if (item.id == null) return;
    await _repository.deleteVocabulary(item.id!);
    await refreshData();
  }

  Future<void> reviewVocabulary(VocabularyItem item, int quality) async {
    await _repository.saveVocabulary(_srs.review(item, quality));
    await logStudy(minutes: 2, skill: 'Vocabulary', source: 'srs', notes: item.term);
  }

  Future<void> saveRecording(RecordingEntry entry) async {
    await _repository.saveRecording(entry);
    await logStudy(
      minutes: (entry.durationSeconds / 60).ceil().clamp(1, 30).toInt(),
      skill: 'Speaking',
      source: 'speaking',
      notes: entry.title,
    );
  }

  Future<void> deleteRecording(RecordingEntry entry) async {
    if (entry.id == null) return;
    final file = File(entry.path);
    if (await file.exists()) await file.delete();
    await _repository.deleteRecording(entry.id!);
    await refreshData();
  }

  Future<void> saveMaterial(MaterialItem item) async {
    if (item.status == 'active') {
      for (final other in materials.where(
        (candidate) => candidate.status == 'active' && candidate.skill == item.skill && candidate.id != item.id,
      )) {
        await _repository.saveMaterial(other.copyWith(status: 'waitlist'));
      }
    }
    await _repository.saveMaterial(item);
    await refreshData();
  }

  Future<void> deleteMaterial(MaterialItem item) async {
    if (item.id == null) return;
    await _repository.deleteMaterial(item.id!);
    await refreshData();
  }

  Future<void> saveQuiz(Quiz quiz) async {
    await _repository.saveQuiz(quiz);
    await refreshData();
  }

  Future<void> deleteQuiz(Quiz quiz) async {
    if (quiz.id == null) return;
    await _repository.deleteQuiz(quiz.id!);
    await refreshData();
  }

  Future<void> registerQuizAttempt(Quiz quiz, int score) async {
    if (quiz.id == null) return;
    await _repository.saveQuizAttempt(QuizAttempt(
      quizId: quiz.id!,
      score: score,
      total: quiz.questions.length,
      createdAt: DateTime.now(),
    ));
    await logStudy(minutes: quiz.questions.length * 2, skill: 'Quiz', source: 'quiz');
  }

  Future<void> saveExercise(ExerciseItem item) async {
    await _repository.saveExercise(item);
    await refreshData();
  }

  Future<void> deleteExercise(ExerciseItem item) async {
    if (item.id == null) return;
    await _repository.deleteExercise(item.id!);
    await refreshData();
  }

  Future<void> registerExerciseAttempt(ExerciseItem item, bool correct) async {
    await _repository.saveExercise(item.copyWith(
      completedCount: item.completedCount + 1,
      correctCount: item.correctCount + (correct ? 1 : 0),
    ));
    await logStudy(minutes: 3, skill: item.category, source: 'exercise');
  }

  Future<void> setUnitProgress(CurriculumUnit unit, int score) async {
    await _repository.setCurriculumProgress(unit.id, score);
    if (score > 0) {
      await logStudy(minutes: 20, skill: 'Curriculum', source: 'unit', notes: unit.title);
    } else {
      await refreshData();
    }
  }

  Future<List<PlayerBookmark>> bookmarksFor(int materialId) =>
      _repository.getBookmarks(materialId);

  Future<void> addBookmark(PlayerBookmark bookmark) =>
      _repository.saveBookmark(bookmark);

  Future<void> deleteBookmark(PlayerBookmark bookmark) async {
    if (bookmark.id == null) return;
    await _repository.deleteBookmark(bookmark.id!);
  }

  Future<File> exportBackup() => _backupService.exportBackup();

  Future<void> importBackup() async {
    await _backupService.importBackup();
    await refreshData();
  }

  String _dateKey(DateTime value) => '${value.year}-${value.month}-${value.day}';
}
