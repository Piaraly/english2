import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_controller.dart';
import '../../models/quiz_models.dart';
import '../../widgets/empty_state.dart';
import 'quiz_editor_screen.dart';
import 'quiz_runner_screen.dart';

class QuizzesScreen extends StatelessWidget {
  const QuizzesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quizzes'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizEditorScreen())),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: controller.quizzes.isEmpty
          ? EmptyState(
              icon: Icons.quiz_outlined,
              title: 'Crie um quiz com feedback',
              message: 'Cada pergunta pode ter opções, resposta certa e uma explicação mostrada no final.',
              action: FilledButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizEditorScreen())),
                child: const Text('Criar quiz'),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: controller.quizzes.length,
              itemBuilder: (context, index) {
                final quiz = controller.quizzes[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(child: Text(quiz.level)),
                    title: Text(quiz.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('${quiz.questions.length} perguntas${quiz.description.isEmpty ? '' : ' • ${quiz.description}'}'),
                    onTap: quiz.questions.isEmpty
                        ? null
                        : () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuizRunnerScreen(quiz: quiz))),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => QuizEditorScreen(quiz: quiz)));
                        }
                        if (value == 'delete') _delete(context, quiz);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Editar')),
                        PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizEditorScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Novo quiz'),
      ),
    );
  }

  Future<void> _delete(BuildContext context, Quiz quiz) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar quiz?'),
        content: Text(quiz.title),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<AppController>().deleteQuiz(quiz);
    }
  }
}
