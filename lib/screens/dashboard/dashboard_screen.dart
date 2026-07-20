import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_controller.dart';
import '../../widgets/gradient_mission_card.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/section_header.dart';
import '../curriculum/curriculum_screen.dart';
import '../debts/debts_screen.dart';
import '../focus/focus_session_screen.dart';
import '../settings/settings_screen.dart';
import '../vocabulary/vocabulary_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final next = controller.nextUnit;
    final today = DateFormat("EEEE, d 'de' MMMM", 'pt').format(DateTime.now());
    final todayEvents = controller.eventsForDay(DateTime.now());
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      children: [
        Text(today, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(
          'Seu próximo passo, não tudo de uma vez.',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 18),
        GradientMissionCard(
          eyebrow: 'Missão de hoje',
          title: next?.title ?? 'Consolidação livre',
          subtitle: next == null
              ? 'Revise, grave e use o inglês em contexto real.'
              : '${next.grammar.first} • ${next.vocabulary.first}',
          buttonLabel: 'Iniciar rotina ${controller.routineMode == 'minimum' ? 'mínima' : 'ideal'}',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FocusSessionScreen()),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 138,
          child: Row(
            children: [
              Expanded(
                child: MetricCard(
                  icon: Icons.local_fire_department,
                  value: '${controller.streak}',
                  label: 'sequência',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MetricCard(
                  icon: Icons.bolt,
                  value: '${controller.totalXp}',
                  label: 'XP total',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MetricCard(
                  icon: Icons.pending_actions,
                  value: '${controller.openDebtMinutes}',
                  label: 'min em dívida',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DebtsScreen())),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const SectionHeader(
          title: 'Atalhos que geram prática',
          subtitle: 'Ferramentas curtas, sem navegar por menus infinitos.',
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: MediaQuery.sizeOf(context).width > 650 ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.25,
          children: [
            _QuickAction(
              icon: Icons.map_outlined,
              title: 'Currículo A1–C2',
              subtitle: completedUnitsText(controller),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CurriculumScreen())),
            ),
            _QuickAction(
              icon: Icons.style_outlined,
              title: 'Revisão SRS',
              subtitle: '${controller.dueVocabularyCount} cartões vencidos',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VocabularyScreen(startReview: true))),
            ),
            _QuickAction(
              icon: Icons.mic_none,
              title: 'Speaking agora',
              subtitle: 'Grave 30–60 segundos',
              onTap: () => onNavigate(2),
            ),
            _QuickAction(
              icon: Icons.headphones,
              title: 'Imersão',
              subtitle: 'Player com loop A–B',
              onTap: () => onNavigate(3),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SectionHeader(
          title: 'Hoje',
          subtitle: todayEvents.isEmpty ? 'Nenhum bloco marcado.' : '${todayEvents.length} blocos programados.',
          action: TextButton(onPressed: () => onNavigate(1), child: const Text('Abrir plano')),
        ),
        const SizedBox(height: 10),
        if (todayEvents.isEmpty)
          Card(
            child: ListTile(
              leading: const Icon(Icons.event_available),
              title: const Text('A agenda está livre'),
              subtitle: const Text('Use a rotina mínima ou marque uma ação concreta para hoje.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onNavigate(1),
            ),
          )
        else
          for (final event in todayEvents)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: CheckboxListTile(
                value: event.completed,
                onChanged: (_) => controller.toggleEvent(event),
                title: Text(event.title),
                subtitle: Text('${event.type} • ${DateFormat('HH:mm').format(event.scheduledAt)} • ${event.durationMinutes} min'),
              ),
            ),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Radar de abandono'),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _RadarRow(
                  icon: controller.streak >= 2 ? Icons.check_circle : Icons.warning_amber,
                  title: 'Regra dos 2 dias',
                  value: controller.streak >= 2 ? 'Protegida' : 'Faça uma microação hoje',
                ),
                const Divider(),
                _RadarRow(
                  icon: Icons.inventory_2_outlined,
                  title: 'Materiais ativos',
                  value: '${controller.materials.where((item) => item.status == 'active').length} em uso',
                ),
                const Divider(),
                _RadarRow(
                  icon: Icons.record_voice_over,
                  title: 'Última gravação',
                  value: controller.recordings.isEmpty
                      ? 'Ainda não gravou'
                      : DateFormat('dd/MM').format(controller.recordings.first.createdAt),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        ListTile(
          leading: const Icon(Icons.settings_outlined),
          title: const Text('Ajustar nível, rotina, alarme e aparência'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
        ),
      ],
    );
  }

  String completedUnitsText(AppController controller) =>
      '${controller.completedUnits}/${controller.totalUnits} unidades';
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
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
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon),
                const Spacer(),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      );
}

class _RadarRow extends StatelessWidget {
  const _RadarRow({required this.icon, required this.title, required this.value});
  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      );
}
