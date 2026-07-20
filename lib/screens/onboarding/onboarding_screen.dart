import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_controller.dart';
import '../../core/constants/app_constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;
  String _level = 'A1';
  String _mode = 'minimum';
  TimeOfDay _reminder = const TimeOfDay(hour: 19, minute: 0);
  bool _saving = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Row(
                  children: [
                    Text(
                      'EnglishForge',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const Spacer(),
                    Text('${_page + 1}/4'),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: LinearProgressIndicator(value: (_page + 1) / 4),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (value) => setState(() => _page = value),
                  children: [
                    _WelcomePage(),
                    _LevelPage(
                      selected: _level,
                      onChanged: (value) => setState(() => _level = value),
                    ),
                    _RoutinePage(
                      selected: _mode,
                      onChanged: (value) => setState(() => _mode = value),
                    ),
                    _ReminderPage(
                      time: _reminder,
                      onPick: _pickTime,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    if (_page > 0)
                      TextButton(
                        onPressed: _saving ? null : _previous,
                        child: const Text('Voltar'),
                      ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _saving ? null : (_page == 3 ? _finish : _next),
                      icon: _saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(_page == 3 ? Icons.check : Icons.arrow_forward),
                      label: Text(_page == 3 ? 'Criar meu sistema' : 'Continuar'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  void _next() => _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );

  void _previous() => _pageController.previousPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );

  Future<void> _pickTime() async {
    final result = await showTimePicker(context: context, initialTime: _reminder);
    if (result != null) setState(() => _reminder = result);
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    await context.read<AppController>().finishOnboarding(
          level: _level,
          mode: _mode,
          reminder: _reminder,
        );
    if (mounted) setState(() => _saving = false);
  }
}

class _WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 20),
          Container(
            height: 210,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34),
              gradient: const LinearGradient(
                colors: [Color(0xFF5A52D9), Color(0xFF9A5DE8)],
              ),
            ),
            child: const Stack(
              children: [
                Positioned(
                  right: 28,
                  top: 24,
                  child: Icon(Icons.auto_awesome, size: 66, color: Colors.white30),
                ),
                Center(
                  child: Icon(Icons.school_rounded, size: 104, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Um sistema para usar o que você já tem.',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          const Text(
            'Calendário, currículo A1–C2, speaking, revisão espaçada, quizzes, materiais, player de imersão, faltas e dívida de estudo — tudo offline e sem transformar organização em procrastinação.',
          ),
          const SizedBox(height: 22),
          const _Feature(icon: Icons.looks_one, text: 'Uma próxima ação concreta por vez.'),
          const _Feature(icon: Icons.mic, text: 'Produção oral desde a primeira semana.'),
          const _Feature(icon: Icons.local_fire_department, text: 'Nunca faltar dois dias seguidos.'),
          const _Feature(icon: Icons.inventory_2_outlined, text: 'Um recurso ativo por habilidade.'),
        ],
      );
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            CircleAvatar(child: Icon(icon, size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
          ],
        ),
      );
}

class _LevelPage extends StatelessWidget {
  const _LevelPage({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Onde você quer começar?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          const Text('Você pode mudar depois. A1 pode ser usado apenas como diagnóstico rápido.'),
          const SizedBox(height: 22),
          for (final level in AppConstants.levels)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: RadioListTile<String>(
                value: level,
                groupValue: selected,
                onChanged: (value) => onChanged(value!),
                title: Text(level, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(_description(level)),
              ),
            ),
        ],
      );

  String _description(String level) => switch (level) {
        'A1' => 'Bases, apresentação, rotina e perguntas simples.',
        'A2' => 'Rotina, cidade, experiências e comunicação elementar.',
        'B1' => 'Histórias, conversas simples e séries com legenda em inglês.',
        'B2' => 'Opiniões, independência e conteúdo nativo.',
        'C1' => 'Nuance, apresentações e linguagem académica.',
        _ => 'Refinamento quase nativo e múltiplos registos.',
      };
}

class _RoutinePage extends StatelessWidget {
  const _RoutinePage({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<AppController>();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Escolha o ritmo sustentável.',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        const Text('O modo mínimo é o piso para semanas difíceis. O ideal exige mais tempo e pode acelerar o plano.'),
        const SizedBox(height: 24),
        for (final mode in const ['minimum', 'ideal'])
          Card(
            margin: const EdgeInsets.only(bottom: 14),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => onChanged(mode),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Radio<String>(value: mode, groupValue: selected, onChanged: (value) => onChanged(value!)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mode == 'minimum' ? 'Rotina mínima' : 'Rotina ideal',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          for (final block in controller.curriculum.routines[mode] ?? const [])
                            Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Text('• ${block.label}: ${block.minutes} min'),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ReminderPage extends StatelessWidget {
  const _ReminderPage({required this.time, required this.onPick});

  final TimeOfDay time;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Reduza a decisão diária.',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          const Text('Defina um horário habitual. O lembrete funciona localmente, mesmo sem internet.'),
          const SizedBox(height: 34),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  const Icon(Icons.alarm_rounded, size: 72),
                  const SizedBox(height: 16),
                  Text(
                    time.format(context),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: onPick,
                    icon: const Icon(Icons.schedule),
                    label: const Text('Escolher horário'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          const ListTile(
            leading: Icon(Icons.shield_outlined),
            title: Text('Privacidade por padrão'),
            subtitle: Text('Os dados, gravações, quizzes e materiais ficam no aparelho.'),
          ),
          const ListTile(
            leading: Icon(Icons.cloud_off_outlined),
            title: Text('Funciona offline'),
            subtitle: Text('A internet só é necessária para conteúdos externos que você escolher usar.'),
          ),
        ],
      );
}
