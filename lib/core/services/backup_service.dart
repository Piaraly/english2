import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../repositories/app_repository.dart';

class BackupService {
  BackupService({AppRepository? repository})
      : _repository = repository ?? AppRepository();

  final AppRepository _repository;

  Future<File> exportBackup() async {
    final data = await _repository.exportAll();
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      p.join(
        directory.path,
        'english_forge_backup_${DateTime.now().millisecondsSinceEpoch}.json',
      ),
    );
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(data),
      flush: true,
    );
    return file;
  }

  Future<void> importBackup() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    final path = result?.files.single.path;
    if (path == null) return;
    final raw = await File(path).readAsString();
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    await _repository.importAll(decoded);
  }
}
