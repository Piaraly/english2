# Validation report — EnglishForge 2.0

Date: 2026-07-20

## Checks completed in the generation environment

- Parsed all Dart source and test files with a Dart tree-sitter grammar: no syntax-error nodes.
- Checked every relative Dart import: no missing local file.
- Parsed `assets/data/curriculum.json`: valid JSON.
- Verified the curriculum contains 6 CEFR levels and 65 units: A1 (6), A2 (10), B1 (12), B2 (13), C1 (12), C2 (12).
- Compiled `tool/configure_android.py` with Python: valid syntax.
- Tested the Android configuration script against the expected Flutter-generated Kotlin Gradle structure.
- Added unit tests for spaced repetition, streak calculation, daily aggregation and curriculum completeness.
- Resolved the dependency conflict by using `timezone: ^0.11.1` with `flutter_local_notifications: ^22.0.1`.

## Validation performed by GitHub Actions

The workflow is the authoritative native build check. It performs:

1. Flutter dependency resolution;
2. dependency graph output;
3. `flutter analyze`;
4. `flutter test`;
5. universal release APK build;
6. split-per-ABI release APK build;
7. SHA-256 checksum generation.

The generation environment does not contain the Flutter SDK or Android SDK, so no claim is made that a local APK was compiled here. The repository is intentionally configured so the first full Flutter/Gradle/Android build occurs in GitHub Actions, where all required SDK versions are explicitly installed.
