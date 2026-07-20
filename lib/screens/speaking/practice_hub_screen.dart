import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_controller.dart';
import '../../widgets/section_header.dart';
import '../curriculum/curriculum_screen.dart';
import '../exercises/exercises_screen.dart';
import '../quizzes/quizzes_screen.dart';
import '../vocabulary/vocabulary_screen.dart';
import 'speaking_lab_screen.dart';

class PracticeHubScreen extends StatelessWidget {
  const PracticeHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      children: [
        Text(
          'Laboratório de prática',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        const Text('Produção ativa, revisão e feedback. Escolha algo que exija uma resposta sua.'),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.record_voice_over, size: 38),
                const SizedBox(height: 12),
                Text(
                  'Escada de speaking',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text('${controller.recordings.length} gravações guardadas • compare com a de 4 semanas atrás'),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SpeakingLabScreen())),
                    icon: const Icon(Icons.mic),
                    label: const Text('Abrir speaking lab'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        const SectionHeader(title: 'Ferramentas de prática'),
        const SizedBox(height: 10),
        _ToolTile(
          icon: Icons.style,
          title: 'Vocabulário e frases',
          subtitle: '${controller.dueVocabularyCount} revisões vencidas • algoritmo de repetição espaçada',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VocabularyScreen())),
        ),
        _ToolTile(
          icon: Icons.quiz_outlined,
          title: 'Quizzes com feedback',
          subtitle: '${controller.quizzes.length} quizzes • múltiplas perguntas e explicações',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizzesScreen())),
        ),
        _ToolTile(
          icon: Icons.edit_note,
          title: 'Banco de exercícios',
          subtitle: '${controller.exercises.length} exercícios • tradução, lacunas e reescrita',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExercisesScreen())),
        ),
        _ToolTile(
          icon: Icons.map_outlined,
          title: 'Currículo guiado',
          subtitle: 'Gramática e vocabulário completos do A1 ao C2',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CurriculumScreen())),
        ),
        const SizedBox(height: 22),
        const SectionHeader(title: 'Microações de 2 minutos'),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              for (final action in const [
                'Fale três frases sobre o que está fazendo agora.',
                'Revise cinco palavras vencidas.',
                'Ouça 60 segundos e imite uma frase.',
                'Explique uma regra de gramática como se ensinasse um amigo.',
              ])
                ListTile(
                  leading: const Icon(Icons.rocket_launch_outlined),
                  title: Text(action),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _completeMicroAction(context, action),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _completeMicroAction(BuildContext context, String action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Só dois minutos'),
        content: Text(action),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Ainda não')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Fiz')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<AppController>().logStudy(
            minutes: 2,
            skill: 'Microação',
            source: 'two_minute',
            notes: action,
          );
    }
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          leading: CircleAvatar(child: Icon(icon)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
}
