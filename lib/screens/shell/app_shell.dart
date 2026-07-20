import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_controller.dart';
import '../calendar/calendar_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../materials/materials_screen.dart';
import '../progress/progress_screen.dart';
import '../speaking/practice_hub_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _destinations = [
    NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Hoje'),
    NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Plano'),
    NavigationDestination(icon: Icon(Icons.mic_none), selectedIcon: Icon(Icons.mic), label: 'Prática'),
    NavigationDestination(icon: Icon(Icons.folder_outlined), selectedIcon: Icon(Icons.folder), label: 'Materiais'),
    NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Progresso'),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final pages = [
      DashboardScreen(onNavigate: (value) => setState(() => _index = value)),
      const CalendarScreen(),
      const PracticeHubScreen(),
      const MaterialsScreen(),
      const ProgressScreen(),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final appBar = AppBar(
          title: const Text('EnglishForge', style: TextStyle(fontWeight: FontWeight.w900)),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Chip(
                avatar: const Icon(Icons.local_fire_department, size: 18),
                label: Text('${controller.streak} dias'),
              ),
            ),
          ],
        );
        if (wide) {
          return Scaffold(
            appBar: appBar,
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: (value) => setState(() => _index = value),
                  labelType: NavigationRailLabelType.all,
                  destinations: _destinations
                      .map((item) => NavigationRailDestination(
                            icon: item.icon,
                            selectedIcon: item.selectedIcon,
                            label: Text(item.label),
                          ))
                      .toList(),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: pages[_index]),
              ],
            ),
          );
        }
        return Scaffold(
          appBar: appBar,
          body: pages[_index],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (value) => setState(() => _index = value),
            destinations: _destinations,
          ),
        );
      },
    );
  }
}
