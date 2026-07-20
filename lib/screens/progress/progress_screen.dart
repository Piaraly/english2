import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_controller.dart';
import '../../core/utils/progress_math.dart';
import '../../models/study_log.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/section_header.dart';
import '../debts/debts_screen.dart';
import '../settings/settings_screen.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final minutesByDay = ProgressMath.minutesByDay(controller.logs);
    final today = DateTime.now();
    final week = List.generate(7, (index) {
      final day = DateTime(today.year, today.month, today.day).subtract(Duration(days: 6 - index));
      return MapEntry(day, minutesByDay[day] ?? 0);
    });
    final skillMinutes = <String, int>{};
    for (final log in controller.logs) {
      skillMinutes[log.skill] = (skillMinutes[log.skill] ?? 0) + log.minutes;
    }
    final recent = controller.logs.take(12).toList();
    final averageQuiz = controller.quizAttempts.isEmpty
        ? 0.0
        : controller.quizAttempts
                .map((attempt) => attempt.total == 0 ? 0.0 : attempt.score / attempt.total)
                .reduce((a, b) => a + b) /
            controller.quizAttempts.length;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: SectionHeader(
                  eyebrow: 'PROGRESSO REAL, NÃO SENSAÇÃO',
                  title: 'Seu painel de evolução',
                  subtitle: 'Minutos, speaking, currículo, revisões e consistência ficam visíveis no mesmo lugar.',
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Definições e backup',
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900 ? 4 : constraints.maxWidth >= 540 ? 2 : 1;
              return GridView.count(
                crossAxisCount: columns,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: columns == 1 ? 3.2 : 2.2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  MetricCard(icon: Icons.timer_outlined, value: '${controller.totalMinutes}', label: 'minutos estudados'),
                  MetricCard(icon: Icons.local_fire_department_outlined, value: '${controller.streak}', label: 'dias de sequência'),
                  MetricCard(icon: Icons.bolt_outlined, value: '${controller.totalXp}', label: 'XP acumulado'),
                  MetricCard(icon: Icons.school_outlined, value: '${controller.completedUnits}/${controller.totalUnits}', label: 'unidades iniciadas'),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Últimos 7 dias', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900))),
                      Text('${week.fold<int>(0, (sum, item) => sum + item.value)} min'),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(height: 180, child: _WeeklyChart(values: week, target: controller.dailyMinutes)),
                  const SizedBox(height: 10),
                  Text('Meta diária atual: ${controller.dailyMinutes} minutos. Barras com a linha indicam dias em que atingiu a meta.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _CurriculumCard(controller: controller),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final quality = _QualityCard(
                speakingCount: controller.recordings.length,
                dueVocabulary: controller.dueVocabularyCount,
                averageQuiz: averageQuiz,
                exerciseAccuracy: _exerciseAccuracy(controller),
              );
              if (constraints.maxWidth >= 760) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _SkillCard(skillMinutes: skillMinutes)),
                    const SizedBox(width: 12),
                    Expanded(child: quality),
                  ],
                );
              }
              return Column(
                children: [
                  _SkillCard(skillMinutes: skillMinutes),
                  const SizedBox(height: 12),
                  quality,
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Card(
            color: controller.openDebtMinutes > 0 ? Theme.of(context).colorScheme.errorContainer : null,
            child: ListTile(
              leading: Icon(controller.openDebtMinutes > 0 ? Icons.account_balance_wallet_outlined : Icons.verified_outlined),
              title: Text(controller.openDebtMinutes > 0 ? '${controller.openDebtMinutes} minutos de dívida de estudo' : 'Nenhuma dívida pendente'),
              subtitle: Text(controller.openDebtMinutes > 0
                  ? 'A dívida é paga gradualmente pelos próximos blocos, sem maratonas punitivas.'
                  : 'A consistência está protegida. Continue evitando dois dias seguidos sem estudar.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DebtsScreen())),
            ),
          ),
          const SizedBox(height: 22),
          Text('Atividade recente', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          if (recent.isEmpty)
            const Card(child: ListTile(leading: Icon(Icons.history), title: Text('Sua atividade aparecerá aqui depois da primeira sessão.')))
          else
            ...recent.map((log) => _LogTile(log: log)),
          const SizedBox(height: 22),
          Text('Régua dos 8 meses', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          ...controller.curriculum.months.map((month) => Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('${month.month}')),
                  title: Text(month.focus, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(month.milestone),
                ),
              )),
        ],
      ),
    );
  }

  double _exerciseAccuracy(AppController controller) {
    final attempts = controller.exercises.fold<int>(0, (sum, item) => sum + item.completedCount);
    final correct = controller.exercises.fold<int>(0, (sum, item) => sum + item.correctCount);
    return attempts == 0 ? 0 : correct / attempts;
  }
}

class _CurriculumCard extends StatelessWidget {
  const _CurriculumCard({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text('Currículo A1 → C2', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900))),
                Text('${(controller.curriculumCompletion * 100).round()}%'),
              ]),
              const SizedBox(height: 12),
              LinearProgressIndicator(value: controller.curriculumCompletion, minHeight: 10, borderRadius: BorderRadius.circular(99)),
              const SizedBox(height: 10),
              Text(controller.nextUnit == null
                  ? 'Todos os conteúdos foram trabalhados.'
                  : 'Próxima ação concreta: ${controller.nextUnit!.title} — ${controller.nextUnit!.grammar.first}.'),
            ],
          ),
        ),
      );
}

class _SkillCard extends StatelessWidget {
  const _SkillCard({required this.skillMinutes});
  final Map<String, int> skillMinutes;

  @override
  Widget build(BuildContext context) {
    final sorted = skillMinutes.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxValue = sorted.isEmpty ? 1 : sorted.first.value;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tempo por habilidade', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            if (sorted.isEmpty)
              const Text('Ainda não há dados.')
            else
              ...sorted.take(8).map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [Expanded(child: Text(entry.key)), Text('${entry.value} min')]),
                        const SizedBox(height: 5),
                        LinearProgressIndicator(value: entry.value / maxValue),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

class _QualityCard extends StatelessWidget {
  const _QualityCard({
    required this.speakingCount,
    required this.dueVocabulary,
    required this.averageQuiz,
    required this.exerciseAccuracy,
  });

  final int speakingCount;
  final int dueVocabulary;
  final double averageQuiz;
  final double exerciseAccuracy;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Indicadores de qualidade', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.mic_none), title: const Text('Áudios de speaking'), trailing: Text('$speakingCount')),
              ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.style_outlined), title: const Text('Cartões para rever'), trailing: Text('$dueVocabulary')),
              ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.quiz_outlined), title: const Text('Média dos quizzes'), trailing: Text('${(averageQuiz * 100).round()}%')),
              ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.task_alt), title: const Text('Precisão nos exercícios'), trailing: Text('${(exerciseAccuracy * 100).round()}%')),
            ],
          ),
        ),
      );
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.log});
  final StudyLog log;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: CircleAvatar(child: Text('${log.minutes}m')),
          title: Text(log.skill, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('${DateFormat('dd MMM, HH:mm', 'pt').format(log.date)}${log.notes.isEmpty ? '' : ' • ${log.notes}'}'),
          trailing: Text('+${log.xp} XP'),
        ),
      );
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.values, required this.target});
  final List<MapEntry<DateTime, int>> values;
  final int target;

  @override
  Widget build(BuildContext context) {
    final maxValue = math.max(target, values.fold<int>(1, (max, item) => math.max(max, item.value)));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: values.map((entry) {
        final ratio = entry.value / maxValue;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('${entry.value}', style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 4),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: ratio.clamp(0.03, 1.0).toDouble(),
                      widthFactor: 0.7,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: entry.value >= target
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(DateFormat('E', 'pt').format(entry.key).substring(0, 3)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
