import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _onboardingKey = 'onboarding_complete';
  static const _levelKey = 'current_level';
  static const _routineKey = 'routine_mode';
  static const _themeKey = 'theme_mode';
  static const _dailyMinutesKey = 'daily_minutes';
  static const _reminderHourKey = 'reminder_hour';
  static const _reminderMinuteKey = 'reminder_minute';
  static const _startedAtKey = 'started_at';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<bool> get onboardingComplete async =>
      (await _prefs).getBool(_onboardingKey) ?? false;

  Future<void> setOnboardingComplete(bool value) async =>
      (await _prefs).setBool(_onboardingKey, value);

  Future<String> get currentLevel async =>
      (await _prefs).getString(_levelKey) ?? 'A1';

  Future<void> setCurrentLevel(String value) async =>
      (await _prefs).setString(_levelKey, value);

  Future<String> get routineMode async =>
      (await _prefs).getString(_routineKey) ?? 'minimum';

  Future<void> setRoutineMode(String value) async =>
      (await _prefs).setString(_routineKey, value);

  Future<int> get dailyMinutes async =>
      (await _prefs).getInt(_dailyMinutesKey) ?? 55;

  Future<void> setDailyMinutes(int value) async =>
      (await _prefs).setInt(_dailyMinutesKey, value);

  Future<TimeOfDay> get reminderTime async {
    final prefs = await _prefs;
    return TimeOfDay(
      hour: prefs.getInt(_reminderHourKey) ?? 19,
      minute: prefs.getInt(_reminderMinuteKey) ?? 0,
    );
  }

  Future<void> setReminderTime(TimeOfDay value) async {
    final prefs = await _prefs;
    await prefs.setInt(_reminderHourKey, value.hour);
    await prefs.setInt(_reminderMinuteKey, value.minute);
  }


  Future<DateTime> getOrCreateStartedAt() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_startedAtKey);
    if (raw != null) return DateTime.parse(raw);
    final now = DateTime.now();
    await prefs.setString(_startedAtKey, now.toIso8601String());
    return now;
  }

  Future<ThemeMode> get themeMode async {
    final raw = (await _prefs).getString(_themeKey) ?? 'system';
    return ThemeMode.values.firstWhere(
      (item) => item.name == raw,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setThemeMode(ThemeMode value) async =>
      (await _prefs).setString(_themeKey, value.name);
}
