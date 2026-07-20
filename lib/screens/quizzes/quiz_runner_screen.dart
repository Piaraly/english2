import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_controller.dart';
import '../../models/quiz_models.dart';

class QuizRunnerScreen extends StatefulWidget {
  const QuizRunnerScreen({super.key, required this.quiz});
  final Quiz quiz;

  @override
  State<QuizRunnerScreen> createState() => _QuizRunnerScreenState();
}

class _QuizRunnerScreenState extends State<QuizRunnerScreen> {
  int _index = 0;
  int _score = 0;
  String? _selected;
  bool _answered = false;
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    if (_index >= widget.quiz.questions.length) return _result(context);
    final question = widget.quiz.questions[_index];
    return Scaffold(
      appBar: AppBar(title: Text(widget.quiz.title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(value: (_index + 1) / widget.quiz.questions.length),
              const SizedBox(height: 18),
              Text('Pergunta ${_index + 1}/${widget.quiz.questions.length}', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Text(question.prompt, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 18),
              Expanded(
                child: ListView(
                  children: [
                    for (final option in question.options)
                      Card(
                        margin: const EdgeInsets.only(bottom: 9),
                        color: _answered
                            ? option == question.answer
                                ? Theme.of(context).colorScheme.primaryContainer
                                : option == _selected
                                    ? Theme.of(context).colorScheme.errorContainer
                                    : null
                            : null,
                        child: RadioListTile<String>(
                          value: option,
                          groupValue: _selected,
                          onChanged: _answered ? null : (value) => setState(() => _selected = value),
                          title: Text(option),
                        ),
                      ),
                    if (_answered) ...[
                      const SizedBox(height: 10),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selected == question.answer ? 'Correto' : 'Resposta: ${question.answer}',
                                style: const TextStyle(fontWeight: FontWeight.w900),
                              ),
                              if (question.explanation.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(question.explanation),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _selected == null ? null : (_answered ? _next : _answer),
                  child: Text(_answered ? 'Próxima' : 'Responder'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _answer() {
    final question = widget.quiz.questions[_index];
    if (_selected == question.answer) _score += 1;
    setState(() => _answered = true);
  }

  void _next() => setState(() {
        _index += 1;
        _selected = null;
        _answered = false;
      });

  Widget _result(BuildContext context) {
    final total = widget.quiz.questions.length;
    final percent = total == 0 ? 0 : (_score / total * 100).round();
    if (!_saved) {
      _saved = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<AppController>().registerQuizAttempt(widget.quiz, _score);
      });
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Resultado')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events_outlined, size: 96),
              const SizedBox(height: 18),
              Text('$_score/$total', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w900)),
              Text('$percent% de acertos'),
              const SizedBox(height: 12),
              Text(percent >= 80 ? 'Bom domínio. Avance e revise depois.' : 'Use os erros para criar palavras, frases ou exercícios.'),
              const SizedBox(height: 24),
              FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Concluir')),
            ],
          ),
        ),
      ),
    );
  }
}
