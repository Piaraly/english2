import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../models/quiz_models.dart';

class QuizEditorScreen extends StatefulWidget {
  const QuizEditorScreen({super.key, this.quiz});
  final Quiz? quiz;

  @override
  State<QuizEditorScreen> createState() => _QuizEditorScreenState();
}

class _QuizEditorScreenState extends State<QuizEditorScreen> {
  late TextEditingController _title;
  late TextEditingController _description;
  late String _level;
  late List<_QuestionDraft> _questions;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.quiz?.title ?? '');
    _description = TextEditingController(text: widget.quiz?.description ?? '');
    _level = widget.quiz?.level ?? 'A1';
    _questions = (widget.quiz?.questions ?? const [])
        .map((question) => _QuestionDraft.fromQuestion(question))
        .toList();
    if (_questions.isEmpty) _questions.add(_QuestionDraft());
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    for (final question in _questions) {
      question.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.quiz == null ? 'Criar quiz' : 'Editar quiz'),
          actions: [
            TextButton(onPressed: _saving ? null : _save, child: const Text('Guardar')),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            TextField(controller: _title, decoration: const InputDecoration(labelText: 'Título do quiz')),
            const SizedBox(height: 10),
            TextField(controller: _description, maxLines: 2, decoration: const InputDecoration(labelText: 'Descrição')),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _level,
              decoration: const InputDecoration(labelText: 'Nível'),
              items: AppConstants.levels.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
              onChanged: (value) => setState(() => _level = value!),
            ),
            const SizedBox(height: 22),
            Text('Perguntas', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            for (var index = 0; index < _questions.length; index++)
              _QuestionEditorCard(
                key: ValueKey(_questions[index]),
                index: index,
                draft: _questions[index],
                canDelete: _questions.length > 1,
                onDelete: () => setState(() {
                  _questions[index].dispose();
                  _questions.removeAt(index);
                }),
              ),
            OutlinedButton.icon(
              onPressed: () => setState(() => _questions.add(_QuestionDraft())),
              icon: const Icon(Icons.add),
              label: const Text('Adicionar pergunta'),
            ),
          ],
        ),
      );

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      _message('Dê um título ao quiz.');
      return;
    }
    final questions = <QuizQuestion>[];
    for (final draft in _questions) {
      final options = draft.options.map((controller) => controller.text.trim()).where((value) => value.isNotEmpty).toList();
      final answer = draft.answer.text.trim();
      if (draft.prompt.text.trim().isEmpty || options.length < 2 || !options.contains(answer)) {
        _message('Cada pergunta precisa de texto, pelo menos duas opções e uma resposta exatamente igual a uma opção.');
        return;
      }
      questions.add(QuizQuestion(
        prompt: draft.prompt.text.trim(),
        options: options,
        answer: answer,
        explanation: draft.explanation.text.trim(),
      ));
    }
    setState(() => _saving = true);
    await context.read<AppController>().saveQuiz(Quiz(
          id: widget.quiz?.id,
          title: _title.text.trim(),
          level: _level,
          description: _description.text.trim(),
          createdAt: widget.quiz?.createdAt ?? DateTime.now(),
          questions: questions,
        ));
    if (!mounted) return;
    Navigator.pop(context);
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

class _QuestionEditorCard extends StatelessWidget {
  const _QuestionEditorCard({
    super.key,
    required this.index,
    required this.draft,
    required this.canDelete,
    required this.onDelete,
  });

  final int index;
  final _QuestionDraft draft;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Text('Pergunta ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w900)),
                  const Spacer(),
                  if (canDelete) IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline)),
                ],
              ),
              TextField(controller: draft.prompt, maxLines: 2, decoration: const InputDecoration(labelText: 'Pergunta')),
              const SizedBox(height: 10),
              for (var optionIndex = 0; optionIndex < draft.options.length; optionIndex++) ...[
                TextField(
                  controller: draft.options[optionIndex],
                  decoration: InputDecoration(labelText: 'Opção ${optionIndex + 1}'),
                ),
                const SizedBox(height: 8),
              ],
              TextField(
                controller: draft.answer,
                decoration: const InputDecoration(labelText: 'Resposta certa (copie exatamente uma opção)'),
              ),
              const SizedBox(height: 8),
              TextField(controller: draft.explanation, maxLines: 2, decoration: const InputDecoration(labelText: 'Explicação / feedback')),
            ],
          ),
        ),
      );
}

class _QuestionDraft {
  _QuestionDraft({
    String prompt = '',
    List<String> options = const ['', '', '', ''],
    String answer = '',
    String explanation = '',
  })  : prompt = TextEditingController(text: prompt),
        options = options.map((value) => TextEditingController(text: value)).toList(),
        answer = TextEditingController(text: answer),
        explanation = TextEditingController(text: explanation);

  factory _QuestionDraft.fromQuestion(QuizQuestion question) => _QuestionDraft(
        prompt: question.prompt,
        options: [...question.options, ...List.filled((4 - question.options.length).clamp(0, 4).toInt(), '')],
        answer: question.answer,
        explanation: question.explanation,
      );

  final TextEditingController prompt;
  final List<TextEditingController> options;
  final TextEditingController answer;
  final TextEditingController explanation;

  void dispose() {
    prompt.dispose();
    for (final option in options) {
      option.dispose();
    }
    answer.dispose();
    explanation.dispose();
  }
}
