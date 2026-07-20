import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_controller.dart';
import '../../models/material_item.dart';
import '../../models/player_bookmark.dart';

class ImmersionPlayerScreen extends StatefulWidget {
  const ImmersionPlayerScreen({super.key, required this.material});

  final MaterialItem material;

  @override
  State<ImmersionPlayerScreen> createState() => _ImmersionPlayerScreenState();
}

class _ImmersionPlayerScreenState extends State<ImmersionPlayerScreen> {
  final AudioPlayer _player = AudioPlayer();
  late AppController _controller;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  bool _initialized = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Duration? _loopStart;
  Duration? _loopEnd;
  double _speed = 1;
  bool _loading = true;
  String? _error;
  List<PlayerBookmark> _bookmarks = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = context.read<AppController>();
    if (!_initialized) {
      _initialized = true;
      _initialize();
    }
  }

  Future<void> _initialize() async {
    try {
      final duration = await _player.setFilePath(widget.material.path);
      if (widget.material.lastPositionMs > 0) {
        await _player.seek(Duration(milliseconds: widget.material.lastPositionMs));
      }
      _positionSubscription = _player.positionStream.listen((position) {
        if (!mounted) return;
        if (_loopEnd != null && _loopStart != null && position >= _loopEnd!) {
          _player.seek(_loopStart!);
        }
        setState(() => _position = position);
      });
      _durationSubscription = _player.durationStream.listen((value) {
        if (mounted && value != null) setState(() => _duration = value);
      });
      if (mounted) {
        final materialId = widget.material.id;
        final bookmarks = materialId == null
            ? <PlayerBookmark>[]
            : await _controller.bookmarksFor(materialId);
        setState(() {
          _duration = duration ?? Duration.zero;
          _bookmarks = bookmarks;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  @override
  void dispose() {
    _savePosition();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _savePosition() async {
    final durationMs = _duration.inMilliseconds;
    final progress = durationMs <= 0 ? widget.material.progress : (_position.inMilliseconds / durationMs).clamp(0.0, 1.0).toDouble();
    await _controller.saveMaterial(widget.material.copyWith(
          lastPositionMs: _position.inMilliseconds,
          progress: progress,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (_, __) => _savePosition(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Immersion Player')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Padding(padding: const EdgeInsets.all(24), child: SelectableText('Não foi possível abrir o áudio.\n\n$_error')))
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _hero(context),
                      const SizedBox(height: 24),
                      Slider(
                        value: _position.inMilliseconds.clamp(0, _duration.inMilliseconds <= 0 ? 1 : _duration.inMilliseconds).toDouble(),
                        max: (_duration.inMilliseconds <= 0 ? 1 : _duration.inMilliseconds).toDouble(),
                        onChanged: (value) => _player.seek(Duration(milliseconds: value.round())),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [Text(_format(_position)), Text(_format(_duration))],
                        ),
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<PlayerState>(
                        stream: _player.playerStateStream,
                        builder: (context, snapshot) {
                          final playing = snapshot.data?.playing ?? false;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton.filledTonal(
                                tooltip: 'Voltar 10 segundos',
                                onPressed: () => _seekRelative(const Duration(seconds: -10)),
                                icon: const Icon(Icons.replay_10),
                              ),
                              const SizedBox(width: 18),
                              IconButton.filled(
                                iconSize: 42,
                                padding: const EdgeInsets.all(18),
                                onPressed: playing ? _player.pause : _player.play,
                                icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                              ),
                              const SizedBox(width: 18),
                              IconButton.filledTonal(
                                tooltip: 'Avançar 10 segundos',
                                onPressed: () => _seekRelative(const Duration(seconds: 10)),
                                icon: const Icon(Icons.forward_10),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      _speedControl(context),
                      const SizedBox(height: 16),
                      _loopControl(context),
                      const SizedBox(height: 16),
                      _shadowingTools(context),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(child: Text('Marcadores', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800))),
                          FilledButton.tonalIcon(onPressed: _addBookmark, icon: const Icon(Icons.bookmark_add_outlined), label: const Text('Marcar')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_bookmarks.isEmpty)
                        const ListTile(
                          leading: Icon(Icons.bookmarks_outlined),
                          title: Text('Ainda sem marcadores'),
                          subtitle: Text('Marque palavras difíceis, frases úteis ou pontos para repetir.'),
                        )
                      else
                        ..._bookmarks.map((bookmark) => Card(
                              child: ListTile(
                                leading: CircleAvatar(child: Text(_format(Duration(milliseconds: bookmark.positionMs)))),
                                title: Text(bookmark.label),
                                subtitle: bookmark.note.isEmpty ? null : Text(bookmark.note),
                                onTap: () => _player.seek(Duration(milliseconds: bookmark.positionMs)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _deleteBookmark(bookmark),
                                ),
                              ),
                            )),
                    ],
                  ),
      ),
    );
  }

  Widget _hero(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.tertiaryContainer,
          ]),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          children: [
            const Icon(Icons.graphic_eq, size: 70),
            const SizedBox(height: 12),
            Text(widget.material.name, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text('${widget.material.level} • ${widget.material.skill} • offline'),
          ],
        ),
      );

  Widget _speedControl(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.speed),
                const SizedBox(width: 10),
                Text('Velocidade para compreensão e shadowing', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const Spacer(),
                Text('${_speed.toStringAsFixed(2)}×'),
              ]),
              Slider(
                min: 0.5,
                max: 2,
                divisions: 12,
                value: _speed,
                onChanged: (value) async {
                  await _player.setSpeed(value);
                  if (mounted) setState(() => _speed = value);
                },
              ),
            ],
          ),
        ),
      );

  Widget _loopControl(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Loop A–B', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Repita uma frase curta até copiar ritmo, ligação e entonação.'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _loopStart = _position),
                    icon: const Icon(Icons.first_page),
                    label: Text(_loopStart == null ? 'Definir A' : 'A ${_format(_loopStart!)}'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _loopStart == null || _position <= _loopStart!
                        ? null
                        : () => setState(() => _loopEnd = _position),
                    icon: const Icon(Icons.last_page),
                    label: Text(_loopEnd == null ? 'Definir B' : 'B ${_format(_loopEnd!)}'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _loopStart == null ? null : () => _player.seek(_loopStart),
                    icon: const Icon(Icons.repeat),
                    label: const Text('Repetir agora'),
                  ),
                  TextButton.icon(
                    onPressed: _loopStart == null && _loopEnd == null
                        ? null
                        : () => setState(() {
                              _loopStart = null;
                              _loopEnd = null;
                            }),
                    icon: const Icon(Icons.clear),
                    label: const Text('Limpar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _shadowingTools(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Método em 4 passagens', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              const _Step(number: 1, text: 'Ouça sem pausar e estime a compreensão.'),
              const _Step(number: 2, text: 'Ouça mais lento e marque palavras/frases.'),
              const _Step(number: 3, text: 'Faça loop A–B e repita junto com o áudio.'),
              const _Step(number: 4, text: 'Grave-se na área Speaking e compare.'),
            ],
          ),
        ),
      );

  Future<void> _seekRelative(Duration delta) async {
    final next = _position + delta;
    final bounded = next < Duration.zero
        ? Duration.zero
        : next > _duration
            ? _duration
            : next;
    await _player.seek(bounded);
  }

  Future<void> _addBookmark() async {
    final materialId = widget.material.id;
    if (materialId == null) return;
    final label = TextEditingController(text: 'Frase em ${_format(_position)}');
    final note = TextEditingController();
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo marcador'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: label, decoration: const InputDecoration(labelText: 'Título')),
            const SizedBox(height: 12),
            TextField(controller: note, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Nota, transcrição ou tradução')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Guardar')),
        ],
      ),
    );
    if (save != true || !mounted) return;
    await _controller.addBookmark(PlayerBookmark(
          materialId: materialId,
          positionMs: _position.inMilliseconds,
          label: label.text.trim().isEmpty ? 'Marcador' : label.text.trim(),
          note: note.text.trim(),
        ));
    final bookmarks = await _controller.bookmarksFor(materialId);
    if (mounted) setState(() => _bookmarks = bookmarks);
  }

  Future<void> _deleteBookmark(PlayerBookmark bookmark) async {
    await _controller.deleteBookmark(bookmark);
    final materialId = widget.material.id;
    if (materialId == null) return;
    final bookmarks = await _controller.bookmarksFor(materialId);
    if (mounted) setState(() => _bookmarks = bookmarks);
  }

  String _format(Duration duration) {
    final total = duration.inSeconds;
    final minutes = total ~/ 60;
    final seconds = total % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});
  final int number;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(radius: 13, child: Text('$number')),
            const SizedBox(width: 10),
            Expanded(child: Text(text)),
          ],
        ),
      );
}
