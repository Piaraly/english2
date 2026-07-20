import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../controllers/app_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../models/study_event.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_header.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _format = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final selectedEvents = controller.eventsForDay(_selectedDay);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Plano e calendário',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Aplicar modelo semanal',
              onPressed: () => _applyWeeklyTemplate(context),
              icon: const Icon(Icons.auto_awesome),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Adicionar bloco',
              onPressed: () => _showEventEditor(context, selectedDate: _selectedDay),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TableCalendar<StudyEvent>(
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 730)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
              calendarFormat: _format,
              availableCalendarFormats: const {
                CalendarFormat.month: 'Mês',
                CalendarFormat.twoWeeks: '2 semanas',
                CalendarFormat.week: 'Semana',
              },
              eventLoader: controller.eventsForDay,
              onFormatChanged: (value) => setState(() => _format = value),
              onDaySelected: (selected, focused) => setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              }),
              onPageChanged: (focused) => _focusedDay = focused,
              calendarStyle: CalendarStyle(
                markerDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiary,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SectionHeader(
          title: DateFormat("EEEE, d 'de' MMMM", 'pt').format(_selectedDay),
          subtitle: selectedEvents.isEmpty ? 'Sem blocos.' : '${selectedEvents.length} blocos programados.',
          action: TextButton.icon(
            onPressed: () => _showEventEditor(context, selectedDate: _selectedDay),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar'),
          ),
        ),
        const SizedBox(height: 10),
        if (selectedEvents.isEmpty)
          EmptyState(
            icon: Icons.event_note,
            title: 'Defina a próxima ação',
            message: 'Evite “estudar inglês”. Marque algo concreto como “Unidade A2-3 por 20 minutos”.',
            action: FilledButton(
              onPressed: () => _showEventEditor(context, selectedDate: _selectedDay),
              child: const Text('Criar bloco'),
            ),
          )
        else
          for (final event in selectedEvents)
            Dismissible(
              key: ValueKey(event.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 22),
                color: Theme.of(context).colorScheme.errorContainer,
                child: const Icon(Icons.delete_outline),
              ),
              confirmDismiss: (_) async =>
                  await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Eliminar bloco?'),
                      content: Text(event.title),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
                        FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Eliminar')),
                      ],
                    ),
                  ) ??
                  false,
              onDismissed: (_) => controller.deleteEvent(event),
              child: Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Checkbox(
                    value: event.completed,
                    onChanged: (_) => controller.toggleEvent(event),
                  ),
                  title: Text(event.title),
                  subtitle: Text(
                    '${DateFormat('HH:mm').format(event.scheduledAt)} • ${event.durationMinutes} min • ${event.type}',
                  ),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _showEventEditor(context, existing: event),
                ),
              ),
            ),
      ],
    );
  }

  Future<void> _showEventEditor(
    BuildContext context, {
    DateTime? selectedDate,
    StudyEvent? existing,
  }) async {
    final controller = context.read<AppController>();
    final title = TextEditingController(text: existing?.title ?? '');
    final notes = TextEditingController(text: existing?.notes ?? '');
    var type = existing?.type ?? 'Conteúdo';
    var duration = existing?.durationMinutes ?? 20;
    var date = existing?.scheduledAt ?? selectedDate ?? DateTime.now();
    var time = TimeOfDay.fromDateTime(existing?.scheduledAt ?? DateTime.now().add(const Duration(minutes: 5)));
    var notify = true;
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(existing == null ? 'Novo bloco de estudo' : 'Editar bloco',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 18),
                TextField(
                  controller: title,
                  autofocus: existing == null,
                  decoration: const InputDecoration(labelText: 'Próxima ação concreta'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: AppConstants.eventTypes
                      .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                      .toList(),
                  onChanged: (value) => setLocalState(() => type = value!),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 730)),
                            initialDate: date,
                          );
                          if (picked != null) setLocalState(() => date = picked);
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(DateFormat('dd/MM/yyyy').format(date)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showTimePicker(context: context, initialTime: time);
                          if (picked != null) setLocalState(() => time = picked);
                        },
                        icon: const Icon(Icons.schedule),
                        label: Text(time.format(context)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: duration,
                  decoration: const InputDecoration(labelText: 'Duração'),
                  items: const [2, 5, 10, 15, 20, 30, 45, 60, 90]
                      .map((value) => DropdownMenuItem(value: value, child: Text('$value minutos')))
                      .toList(),
                  onChanged: (value) => setLocalState(() => duration = value!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notes,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Notas ou material a usar'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: notify,
                  onChanged: (value) => setLocalState(() => notify = value),
                  title: const Text('Criar lembrete local'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(sheetContext, true),
                    child: const Text('Guardar bloco'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (saved != true || title.text.trim().isEmpty) return;
    final scheduled = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    await controller.saveEvent(
      StudyEvent(
        id: existing?.id,
        title: title.text.trim(),
        type: type,
        scheduledAt: scheduled,
        durationMinutes: duration,
        completed: existing?.completed ?? false,
        notes: notes.text.trim(),
        curriculumUnitId: existing?.curriculumUnitId,
        createdAt: existing?.createdAt ?? DateTime.now(),
      ),
      scheduleNotification: notify,
    );
  }

  Future<void> _applyWeeklyTemplate(BuildContext context) async {
    final controller = context.read<AppController>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Aplicar rotina aos próximos 7 dias?'),
        content: Text(
          'Serão criados ${controller.currentRoutine.length} blocos por dia usando a rotina ${controller.routineMode == 'minimum' ? 'mínima' : 'ideal'}. Você poderá editar tudo depois.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Aplicar')),
        ],
      ),
    );
    if (confirmed != true) return;
    for (var dayOffset = 0; dayOffset < 7; dayOffset++) {
      final day = DateTime.now().add(Duration(days: dayOffset));
      var startMinutes = controller.reminderTime.hour * 60 + controller.reminderTime.minute;
      for (final block in controller.currentRoutine) {
        final scheduled = DateTime(day.year, day.month, day.day, startMinutes ~/ 60, startMinutes % 60);
        await controller.saveEvent(StudyEvent(
          title: block.label,
          type: block.label.contains('Imersão') ? 'Imersão' : block.label.contains('Speaking') ? 'Speaking' : 'Conteúdo',
          scheduledAt: scheduled,
          durationMinutes: block.minutes,
          createdAt: DateTime.now(),
        ));
        startMinutes += block.minutes + 5;
      }
    }
  }
}
