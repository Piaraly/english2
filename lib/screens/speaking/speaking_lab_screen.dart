import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import '../../controllers/app_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../models/recording_entry.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_header.dart';

class SpeakingLabScreen extends StatefulWidget {
  const SpeakingLabScreen({super.key});

  @override
  State<SpeakingLabScreen> createState() => _SpeakingLabScreenState();
}

class _SpeakingLabScreenState extends State<SpeakingLabScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  Timer? _timer;
  bool _recording = false;
  int _elapsed = 0;
  String _prompt = AppConstants.recordingPrompts.first;
  String? _playingPath;

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final compareEntry = _findComparison(controller.recordings);
    return Scaffold(
      appBar: AppBar(title: const Text('Speaking lab')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.psychology_alt_outlined),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Prompt de hoje',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Novo prompt',
                        onPressed: _randomPrompt,
                        icon: const Icon(Icons.casino_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(_prompt, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  const Text('Objetivo: continuar falando. Não pare para corrigir cada erro.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: _recording
                  ? Theme.of(context).colorScheme.errorContainer
                  : Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Column(
              children: [
                Text(
                  _formatSeconds(_elapsed),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(_recording ? 'Gravando… fale sem se julgar.' : 'Pronto para 30–60 segundos.'),
                const SizedBox(height: 22),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(190, 56),
                    backgroundColor: _recording ? Theme.of(context).colorScheme.error : null,
                  ),
                  onPressed: _toggleRecording,
                  icon: Icon(_recording ? Icons.stop : Icons.mic),
                  label: Text(_recording ? 'Parar e guardar' : 'Começar gravação'),
                ),
              ],
            ),
          ),
          if (compareEntry != null) ...[
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.compare_arrows)),
                title: const Text('Comparação de 4 semanas'),
                subtitle: Text('Ouça ${DateFormat('dd/MM/yyyy').format(compareEntry.createdAt)} antes de gravar novamente.'),
                trailing: IconButton(
                  onPressed: () => _play(compareEntry.path),
                  icon: Icon(_playingPath == compareEntry.path && _player.playing ? Icons.pause : Icons.play_arrow),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          SectionHeader(
            title: 'Arquivo cronológico',
            subtitle: '${controller.recordings.length} gravações locais',
          ),
          const SizedBox(height: 10),
          if (controller.recordings.isEmpty)
            const EmptyState(
              icon: Icons.mic_none,
              title: 'A primeira gravação é a linha de base',
              message: 'Ela não precisa soar bem. Precisa apenas existir para você comparar o progresso depois.',
            )
          else
            for (final entry in controller.recordings)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(_playingPath == entry.path && _player.playing ? Icons.graphic_eq : Icons.multitrack_audio),
                  ),
                  title: Text(entry.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(
                    '${DateFormat('dd/MM/yyyy HH:mm').format(entry.createdAt)} • ${_formatSeconds(entry.durationSeconds)} • ${entry.level} • autoavaliação ${entry.selfScore}/5',
                  ),
                  onTap: () => _showRecordingDetails(entry),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'play') _play(entry.path);
                      if (value == 'delete') _delete(entry);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'play', child: Text('Reproduzir / pausar')),
                      PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  void _randomPrompt() {
    final prompts = AppConstants.recordingPrompts;
    setState(() => _prompt = prompts[Random().nextInt(prompts.length)]);
  }

  Future<void> _toggleRecording() async {
    if (_recording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    final allowed = await _recorder.hasPermission();
    if (!allowed) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permita o acesso ao microfone para gravar.')),
      );
      return;
    }
    final directory = await getApplicationDocumentsDirectory();
    final recordingsDirectory = Directory(p.join(directory.path, 'recordings'));
    if (!await recordingsDirectory.exists()) await recordingsDirectory.create(recursive: true);
    final path = p.join(recordingsDirectory.path, 'speaking_${DateTime.now().millisecondsSinceEpoch}.m4a');
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );
    setState(() {
      _recording = true;
      _elapsed = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed += 1);
    });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    final path = await _recorder.stop();
    setState(() => _recording = false);
    if (path == null || !mounted) return;
    await _saveRecordingDialog(path);
  }

  Future<void> _saveRecordingDialog(String path) async {
    final titleController = TextEditingController(
      text: 'Speaking ${DateFormat('dd-MM-yyyy').format(DateTime.now())}',
    );
    final notesController = TextEditingController();
    var score = 3.0;
    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: const Text('Guardar gravação'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Título')),
                const SizedBox(height: 12),
                TextField(controller: notesController, maxLines: 3, decoration: const InputDecoration(labelText: 'O que percebeu?')),
                const SizedBox(height: 16),
                Text('Autoavaliação: ${score.round()}/5'),
                Slider(
                  value: score,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  onChanged: (value) => setLocalState(() => score = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Descartar')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Guardar')),
          ],
        ),
      ),
    );
    if (save != true) {
      final file = File(path);
      if (await file.exists()) await file.delete();
      return;
    }
    if (!mounted) return;
    await context.read<AppController>().saveRecording(RecordingEntry(
          path: path,
          title: titleController.text.trim().isEmpty ? 'Speaking' : titleController.text.trim(),
          prompt: _prompt,
          durationSeconds: _elapsed,
          createdAt: DateTime.now(),
          level: context.read<AppController>().currentLevel,
          selfScore: score.round(),
          notes: notesController.text.trim(),
        ));
  }

  Future<void> _play(String path) async {
    if (_playingPath == path && _player.playing) {
      await _player.pause();
      if (mounted) setState(() {});
      return;
    }
    try {
      await _player.setFilePath(path);
      if (mounted) setState(() => _playingPath = path);
      unawaited(_player.play());
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível reproduzir este ficheiro.')),
      );
    }
  }

  Future<void> _delete(RecordingEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar gravação?'),
        content: Text(entry.title),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AppController>().deleteRecording(entry);
    }
  }

  void _showRecordingDetails(RecordingEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            Text('Prompt', style: Theme.of(context).textTheme.labelLarge),
            Text(entry.prompt.isEmpty ? 'Sem prompt' : entry.prompt),
            const SizedBox(height: 14),
            Text('Notas', style: Theme.of(context).textTheme.labelLarge),
            Text(entry.notes.isEmpty ? 'Sem notas' : entry.notes),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => _play(entry.path),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Reproduzir'),
            ),
          ],
        ),
      ),
    );
  }

  RecordingEntry? _findComparison(List<RecordingEntry> entries) {
    if (entries.isEmpty) return null;
    final target = DateTime.now().subtract(const Duration(days: 28));
    RecordingEntry? best;
    var bestDistance = const Duration(days: 9999);
    for (final entry in entries) {
      final distance = entry.createdAt.difference(target).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        best = entry;
      }
    }
    return bestDistance.inDays <= 14 ? best : null;
  }

  String _formatSeconds(int value) =>
      '${(value ~/ 60).toString().padLeft(2, '0')}:${(value % 60).toString().padLeft(2, '0')}';
}
