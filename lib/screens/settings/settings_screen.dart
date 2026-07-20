import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Definições')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
        children: [
          Text('Plano pessoal', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: controller.currentLevel,
                    decoration: const InputDecoration(labelText: 'Nível atual'),
                    items: const ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']
                        .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) controller.setLevel(value);
                    },
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: controller.routineMode,
                    decoration: const InputDecoration(labelText: 'Modo de rotina'),
                    items: const [
                      DropdownMenuItem(value: 'minimum', child: Text('Mínimo sustentável — 45 a 60 min')),
                      DropdownMenuItem(value: 'ideal', child: Text('Ideal — 90 a 150 min')),
                    ],
                    onChanged: (value) {
                      if (value != null) controller.setRoutineMode(value);
                    },
                  ),
                  const SizedBox(height: 18),
                  Row(children: [
                    const Expanded(child: Text('Meta diária personalizada')),
                    Text('${controller.dailyMinutes} min', style: const TextStyle(fontWeight: FontWeight.w800)),
                  ]),
                  Slider(
                    min: 10,
                    max: 180,
                    divisions: 34,
                    value: controller.dailyMinutes.clamp(10, 180).toDouble(),
                    label: '${controller.dailyMinutes} min',
                    onChanged: (value) => controller.setDailyMinutes(value.round()),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text('Lembrete e aparência', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.alarm_outlined),
                  title: const Text('Alarme diário'),
                  subtitle: Text(controller.reminderTime.format(context)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final value = await showTimePicker(context: context, initialTime: controller.reminderTime);
                    if (value != null && context.mounted) {
                      await controller.setReminderTime(value);
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alarme diário atualizado.')));
                    }
                  },
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.phone_android), label: Text('Sistema')),
                      ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_outlined), label: Text('Claro')),
                      ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_outlined), label: Text('Escuro')),
                    ],
                    selected: {controller.themeMode},
                    onSelectionChanged: (value) => controller.setThemeMode(value.first),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('Dados offline', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.upload_file_outlined),
                  title: const Text('Exportar backup JSON'),
                  subtitle: const Text('Calendário, progresso, palavras, quizzes, materiais e dívidas.'),
                  onTap: () => _export(context, controller),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: const Text('Importar backup'),
                  subtitle: const Text('Substitui os dados atuais pelos dados do ficheiro escolhido.'),
                  onTap: () => _import(context, controller),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('Princípios do sistema', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          ...controller.curriculum.principles.map((principle) => Card(
                child: ListTile(
                  leading: const Icon(Icons.psychology_alt_outlined),
                  title: Text(principle.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(principle.body),
                ),
              )),
          const SizedBox(height: 16),
          const Center(child: Text('EnglishForge 2.0 • offline-first • dados apenas no aparelho')),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context, AppController controller) async {
    try {
      final file = await controller.exportBackup();
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Backup criado'),
          content: SelectableText(file.path),
          actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar'))],
        ),
      );
    } catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha ao exportar: $error')));
    }
  }

  Future<void> _import(BuildContext context, AppController controller) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importar backup?'),
        content: const Text('Os dados atuais do app serão substituídos. Os ficheiros de áudio originais não são copiados pelo JSON.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Escolher ficheiro')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await controller.importBackup();
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup importado.')));
    } catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha ao importar: $error')));
    }
  }
}
