import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_controller.dart';
import '../../models/curriculum_models.dart';
import '../../models/study_debt.dart';
import '../../widgets/empty_state.dart';
import '../focus/focus_session_screen.dart';

class DebtsScreen extends StatelessWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final open = controller.debts.where((item) => item.status == 'open').toList();
    final paid = controller.debts.where((item) => item.status == 'paid').toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Faltas e dívida de estudo')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: controller.openDebtMinutes > 0
                  ? Theme.of(context).colorScheme.errorContainer
                  : Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${controller.openDebtMinutes} min', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(controller.openDebtMinutes > 0 ? 'Dívida acumulada' : 'Dívida zerada', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text('O sistema não manda recuperar tudo de uma vez. Cada sessão futura paga primeiro a dívida mais antiga, preservando a consistência sem punição.'),
              ],
            ),
          ),
          if (controller.openDebtMinutes > 0) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final minutes in const [2, 5, 10, 20])
                  FilledButton.tonalIcon(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => FocusSessionScreen(
                        blocks: [RoutineBlock(label: minutes == 2 ? 'Regra dos 2 minutos' : 'Recuperação leve', minutes: minutes)],
                      ),
                    )),
                    icon: const Icon(Icons.play_arrow),
                    label: Text('$minutes min agora'),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          Text('Pendentes', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          if (open.isEmpty)
            const EmptyState(icon: Icons.verified_outlined, title: 'Nada pendente', message: 'Sua próxima meta é apenas proteger a sequência de hoje.')
          else
            ...open.map((debt) => _DebtCard(debt: debt)),
          if (paid.isNotEmpty) ...[
            const SizedBox(height: 24),
            ExpansionTile(
              title: Text('Dívidas recuperadas (${paid.length})'),
              children: paid.take(20).map((debt) => ListTile(
                    leading: const Icon(Icons.check_circle_outline),
                    title: Text(DateFormat('dd MMM yyyy', 'pt').format(debt.date)),
                    subtitle: Text('${debt.plannedMinutes} minutos planeados'),
                  )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _DebtCard extends StatelessWidget {
  const _DebtCard({required this.debt});
  final StudyDebt debt;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                CircleAvatar(child: Text('${debt.outstandingMinutes}m')),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat('EEEE, dd MMM', 'pt').format(debt.date), style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text('Fez ${debt.completedMinutes} de ${debt.plannedMinutes} minutos'),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Registar motivo',
                  onPressed: () => _editReason(context),
                  icon: const Icon(Icons.edit_note),
                ),
              ]),
              if (debt.reason.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text('Motivo: ${debt.reason}'),
              ],
              const SizedBox(height: 10),
              LinearProgressIndicator(value: debt.plannedMinutes == 0 ? 0 : debt.completedMinutes / debt.plannedMinutes),
            ],
          ),
        ),
      );

  Future<void> _editReason(BuildContext context) async {
    final text = TextEditingController(text: debt.reason);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Por que não conseguiu estudar?'),
        content: TextField(
          controller: text,
          minLines: 2,
          maxLines: 5,
          decoration: const InputDecoration(hintText: 'Ex.: prova, cansaço, viagem, procrastinação...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Guardar')),
        ],
      ),
    );
    if (saved == true && context.mounted) {
      await context.read<AppController>().updateDebtReason(debt, text.text.trim());
    }
  }
}
