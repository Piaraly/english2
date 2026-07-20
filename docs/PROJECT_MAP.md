# Project map

## Main user journeys

| Journey | Main implementation |
|---|---|
| Start and personalize the plan | `lib/screens/onboarding/onboarding_screen.dart` |
| See today's mission and risk indicators | `lib/screens/dashboard/dashboard_screen.dart` |
| Plan sessions and alarms | `lib/screens/calendar/calendar_screen.dart` |
| Run a timed minimum/ideal routine | `lib/screens/focus/focus_session_screen.dart` |
| Follow A1–C2 curriculum | `lib/screens/curriculum/curriculum_screen.dart` |
| Record and compare speaking | `lib/screens/speaking/speaking_lab_screen.dart` |
| Review vocabulary with SRS | `lib/screens/vocabulary/vocabulary_screen.dart` |
| Create and run quizzes | `lib/screens/quizzes/` |
| Create and answer exercises | `lib/screens/exercises/exercises_screen.dart` |
| Organize active/waiting materials | `lib/screens/materials/materials_screen.dart` |
| Shadowing player with A–B loop | `lib/screens/materials/immersion_player_screen.dart` |
| Track progress, skill balance and streak | `lib/screens/progress/progress_screen.dart` |
| Record absences and study debt | `lib/screens/debts/debts_screen.dart` |
| Backup, restore and preferences | `lib/screens/settings/settings_screen.dart` |

## Data architecture

- Controller/state: `lib/controllers/app_controller.dart`
- SQLite repository: `lib/repositories/app_repository.dart`
- Schema and seeds: `lib/core/services/database_service.dart`
- Local notifications: `lib/core/services/notification_service.dart`
- Backup/restore: `lib/core/services/backup_service.dart`
- Curriculum source: `assets/data/curriculum.json`

## Android build architecture

- CI workflow: `.github/workflows/build-apk.yml`
- Native post-generation configuration: `tool/configure_android.py`
- Pre-generated launcher resources: `tool/android_resources/`
