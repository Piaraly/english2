import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../models/exercise_item.dart';
import '../../widgets/empty_state.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  String _level = 'Todos';

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final items = controller.exercises.where((item) => _level == 'Todos' || item.level == _level).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercícios'),
        actions: [
          IconButton(onPressed: () => _edit(context), icon: const Icon(Icons.add)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          DropdownButtonFormField<String>(
            value: _level,
            decoration: const InputDecoration(labelText: 'Filtrar por nível'),
            items: ['Todos', ...AppConstants.levels]
                .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                .toList(),
            onChanged: (value) => setState(() => _level = value!),
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            EmptyState(
              icon: Icons.edit_note,
              title: 'Crie exercícios a partir dos seus erros',
              message: 'Tradução, preenchimento, reescrita ou resposta livre. A resposta fica guardada para feedback.',
              action: FilledButton(onPressed: () => _edit(context), child: const Text('Novo exercício')),
            )
          else
            for (final item in items)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(child: Text(item.level)),
                  title: Text(item.prompt, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${item.category} • ${item.correctCount}/${item.completedCount} corretos'),
                  onTap: () => _attempt(context, item),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') _edit(context, item: item);
                      if (value == 'delete') _delete(context, item);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                    ],
                  ),
                ),
              ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context),
        icon: const Icon(Icons.add),
        label: const Text('Novo exercício'),
      ),
    );
  }

  Future<void> _edit(BuildContext context, {ExerciseItem? item}) async {
    final prompt = TextEditingController(text: item?.prompt ?? '');
    final answer = TextEditingController(text: item?.answer ?? '');
    final explanation = TextEditingController(text: item?.explanation ?? '');
    final category = TextEditingController(text: item?.category ?? 'Geral');
    var type = item?.type ?? 'translation';
    var level = item?.level ?? 'A1';
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setLocalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item == null ? 'Novo exercício' : 'Editar exercício',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                TextField(controller: prompt, maxLines: 3, decoration: const InputDecoration(labelText: 'Enunciado')),
                const SizedBox(height: 10),
                TextField(controller: answer, maxLines: 2, decoration: const InputDecoration(labelText: 'Resposta esperada')),
                const SizedBox(height: 10),
                TextField(controller: explanation, maxLines: 2, decoration: const InputDecoration(labelText: 'Explicação / feedback')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: type,
                        decoration: const InputDecoration(labelText: 'Tipo'),
                        items: const {
                          'translation': 'Tradução',
                          'fill_blank': 'Preencher lacuna',
                          'rewrite': 'Reescrita',
                          'free_response': 'Resposta livre',
                        }
                            .entries
                            .map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value)))
                            .toList(),
                        onChanged: (value) => setLocalState(() => type = value!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: level,
                        decoration: const InputDecoration(labelText: 'Nível'),
                        items: AppConstants.levels.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                        onChanged: (value) => setLocalState(() => level = value!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: category, decoration: const InputDecoration(labelText: 'Categoria / tema')),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(onPressed: () => Navigator.pop(sheetContext, true), child: const Text('Guardar')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (saved != true || prompt.text.trim().isEmpty || answer.text.trim().isEmpty || !context.mounted) return;
    await context.read<AppController>().saveExercise(ExerciseItem(
          id: item?.id,
          prompt: prompt.text.trim(),
          answer: answer.text.trim(),
          type: type,
          level: level,
          category: category.text.trim().isEmpty ? 'Geral' : category.text.trim(),
          explanation: explanation.text.trim(),
          completedCount: item?.completedCount ?? 0,
          correctCount: item?.correctCount ?? 0,
          createdAt: item?.createdAt ?? DateTime.now(),
        ));
  }

  Future<void> _attempt(BuildContext context, ExerciseItem item) async {
    final response = TextEditingController();
    var revealed = false;
    var automaticCorrect = false;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: Text('${item.level} • ${item.category}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.prompt, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(controller: response, maxLines: 3, enabled: !revealed, decoration: const InputDecoration(labelText: 'Sua resposta')),
                if (revealed) ...[
                  const SizedBox(height: 16),
                  Text('Resposta esperada', style: Theme.of(context).textTheme.labelLarge),
                  Text(item.answer, style: const TextStyle(fontWeight: FontWeight.w800)),
                  if (item.explanation.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(item.explanation),
                  ],
                ],
              ],
            ),
          ),
          actions: revealed
              ? [
                  TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Preciso rever')),
                  FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(automaticCorrect ? 'Correto' : 'Considerei correto')),
                ]
              : [
                  TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
                  FilledButton(
                    onPressed: response.text.trim().isEmpty
                        ? null
                        : () => setLocalState(() {
                              automaticCorrect = _normalize(response.text) == _normalize(item.answer);
                              revealed = true;
                            }),
                    child: const Text('Verificar'),
                  ),
                ],
        ),
      ),
    );
    if (result != null && context.mounted) {
      await context.read<AppController>().registerExerciseAttempt(item, result);
    }
  }

  Future<void> _delete(BuildContext context, ExerciseItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar exercício?'),
        content: Text(item.prompt),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<AppController>().deleteExercise(item);
    }
  }

  String _normalize(String value) => value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), '').replaceAll(RegExp(r'\s+'), ' ').trim();
}
