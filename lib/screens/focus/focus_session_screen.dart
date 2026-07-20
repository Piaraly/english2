import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_controller.dart';
import '../../models/curriculum_models.dart';

class FocusSessionScreen extends StatefulWidget {
  const FocusSessionScreen({super.key, this.blocks});

  final List<RoutineBlock>? blocks;

  @override
  State<FocusSessionScreen> createState() => _FocusSessionScreenState();
}

class _FocusSessionScreenState extends State<FocusSessionScreen> {
  Timer? _timer;
  int _blockIndex = 0;
  int _remainingSeconds = 0;
  bool _running = false;
  bool _finished = false;

  List<RoutineBlock> get _blocks => widget.blocks ?? context.read<AppController>().currentRoutine;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resetCurrentBlock());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _resetCurrentBlock() {
    if (_blocks.isEmpty) return;
    setState(() {
      _remainingSeconds = _blocks[_blockIndex].minutes * 60;
      _running = false;
    });
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds <= 1) {
        timer.cancel();
        _completeBlock();
      } else {
        setState(() => _remainingSeconds -= 1);
      }
    });
  }

  Future<void> _completeBlock() async {
    final block = _blocks[_blockIndex];
    await context.read<AppController>().logStudy(
          minutes: block.minutes,
          skill: block.label,
          source: 'focus',
        );
    if (!mounted) return;
    if (_blockIndex == _blocks.length - 1) {
      setState(() {
        _running = false;
        _remainingSeconds = 0;
        _finished = true;
      });
    } else {
      setState(() {
        _blockIndex += 1;
        _running = false;
        _remainingSeconds = _blocks[_blockIndex].minutes * 60;
      });
    }
  }

  Future<void> _skipAsDone() => _completeBlock();

  @override
  Widget build(BuildContext context) {
    if (_blocks.isEmpty) {
      return const Scaffold(body: Center(child: Text('Rotina não configurada.')));
    }
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final totalSeconds = _blocks[_blockIndex].minutes * 60;
    final progress = totalSeconds == 0 ? 0.0 : 1 - (_remainingSeconds / totalSeconds);
    return Scaffold(
      appBar: AppBar(title: const Text('Modo foco')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _finished
              ? _FinishedView(totalMinutes: _blocks.fold(0, (sum, item) => sum + item.minutes))
              : Column(
                  children: [
                    Text(
                      'Bloco ${_blockIndex + 1} de ${_blocks.length}',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _blocks[_blockIndex].label,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const Spacer(),
                    SizedBox.square(
                      dimension: 260,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox.expand(
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 16,
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                                style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const Text('sem trocar de tarefa'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _running ? null : _resetCurrentBlock,
                          icon: const Icon(Icons.restart_alt),
                          label: const Text('Reiniciar'),
                        ),
                        const SizedBox(width: 14),
                        FilledButton.icon(
                          onPressed: _toggle,
                          icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                          label: Text(_running ? 'Pausar' : 'Começar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: _running ? null : _skipAsDone,
                      child: const Text('Já fiz este bloco — marcar como concluído'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _FinishedView extends StatelessWidget {
  const _FinishedView({required this.totalMinutes});
  final int totalMinutes;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_rounded, size: 100),
            const SizedBox(height: 18),
            Text(
              'Sessão concluída',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text('$totalMinutes minutos registados. A dívida mais antiga foi reduzida automaticamente.'),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Voltar ao painel'),
            ),
          ],
        ),
      );
}
