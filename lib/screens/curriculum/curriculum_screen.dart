import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_controller.dart';
import '../../models/curriculum_models.dart';
import '../../models/study_event.dart';
import '../../widgets/section_header.dart';

class CurriculumScreen extends StatefulWidget {
  const CurriculumScreen({super.key});

  @override
  State<CurriculumScreen> createState() => _CurriculumScreenState();
}

class _CurriculumScreenState extends State<CurriculumScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    final controller = context.read<AppController>();
    final index = controller.curriculum.levels.indexWhere((level) => level.code == controller.currentLevel);
    _tabs = TabController(
      length: controller.curriculum.levels.length,
      vsync: this,
      initialIndex: index < 0 ? 0 : index,
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Currículo A1–C2'),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: controller.curriculum.levels.map((level) => Tab(text: level.code)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: controller.curriculum.levels
            .map((level) => _LevelView(level: level))
            .toList(),
      ),
    );
  }
}

class _LevelView extends StatelessWidget {
  const _LevelView({required this.level});
  final CurriculumLevel level;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final completed = level.units.where((unit) => (controller.curriculumProgress[unit.id] ?? 0) > 0).length;
    return ListView(
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
                    CircleAvatar(radius: 25, child: Text(level.code, style: const TextStyle(fontWeight: FontWeight.w900))),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(level.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                          Text(level.months),
                        ],
                      ),
                    ),
                    Text('$completed/${level.units.length}', style: const TextStyle(fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(value: level.units.isEmpty ? 0 : completed / level.units.length),
                const SizedBox(height: 12),
                Text(level.target),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const SectionHeader(title: 'Foco do nível'),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              for (final entry in level.skills.entries)
                ListTile(
                  leading: Icon(_skillIcon(entry.key)),
                  title: Text(_skillName(entry.key)),
                  subtitle: Text(entry.value),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        ExpansionTile(
          title: const Text('Pronúncia'),
          leading: const Icon(Icons.record_voice_over),
          children: [
            for (final item in level.pronunciation)
              ListTile(leading: const Icon(Icons.check_rounded), title: Text(item)),
          ],
        ),
        const SizedBox(height: 18),
        SectionHeader(title: 'Unidades', subtitle: '${level.units.length} unidades organizadas'),
        const SizedBox(height: 10),
        for (final unit in level.units)
          _UnitCard(unit: unit),
      ],
    );
  }

  IconData _skillIcon(String key) => switch (key) {
        'speaking' => Icons.mic,
        'listening' => Icons.headphones,
        'reading' => Icons.menu_book,
        _ => Icons.edit_note,
      };

  String _skillName(String key) => switch (key) {
        'speaking' => 'Speaking',
        'listening' => 'Listening',
        'reading' => 'Reading',
        _ => 'Writing',
      };
}

class _UnitCard extends StatelessWidget {
  const _UnitCard({required this.unit});
  final CurriculumUnit unit;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final score = controller.curriculumProgress[unit.id] ?? 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: CircleAvatar(
          child: score > 0 ? const Icon(Icons.check) : Text('${unit.number}'),
        ),
        title: Text(unit.title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(score == 0 ? 'Não iniciada' : 'Domínio: $score/5'),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Gramática', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 6),
          for (final item in unit.grammar)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $item'),
              ),
            ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Vocabulário', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 6),
          for (final item in unit.vocabulary)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $item'),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _schedule(context),
                  icon: const Icon(Icons.event),
                  label: const Text('Agendar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _rate(context, score),
                  icon: const Icon(Icons.fact_check),
                  label: Text(score == 0 ? 'Marcar progresso' : 'Atualizar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _rate(BuildContext context, int current) async {
    var value = current == 0 ? 3.0 : current.toDouble();
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: Text(unit.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Avalie quanto o conteúdo está automático, não apenas reconhecível.'),
              const SizedBox(height: 18),
              Text('${value.round()}/5', style: Theme.of(context).textTheme.headlineMedium),
              Slider(
                value: value,
                min: 0,
                max: 5,
                divisions: 5,
                label: value.round().toString(),
                onChanged: (next) => setLocalState(() => value = next),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, value.round()), child: const Text('Guardar')),
          ],
        ),
      ),
    );
    if (result != null && context.mounted) {
      await context.read<AppController>().setUnitProgress(unit, result);
    }
  }

  Future<void> _schedule(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: DateTime.now(),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null || !context.mounted) return;
    await context.read<AppController>().saveEvent(
          StudyEvent(
            title: unit.title,
            type: 'Conteúdo',
            scheduledAt: DateTime(date.year, date.month, date.day, time.hour, time.minute),
            durationMinutes: 20,
            curriculumUnitId: unit.id,
            createdAt: DateTime.now(),
          ),
          scheduleNotification: true,
        );
  }
}
